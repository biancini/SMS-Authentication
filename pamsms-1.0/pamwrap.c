/* 
 * pamwrap.c
 *
 * Author: Andrea Biancini <andrea.biancini@reti.it> (2004/07/11)
 *         Gruppo Reti S.p.A.
 *
 */

#include <stdio.h>
#include <stdlib.h>

#include <fcntl.h>
#include <unistd.h>

#include <string.h>
#include <time.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/stat.h>

#include <security/pam_appl.h>
#include <security/pam_misc.h>

// Parameters that can be personalizated.
#define PREFIX "/tmp/"
#define PATH_SCRIPT "/usr/share/smsgateway/bin"

// These two variables identify the current session and user
char *sessionID, *username, *service;

// This method deletes all the pipes and files created by the method above
void delete_pipes() {
	char nomepipe[1024];

	sprintf(nomepipe, "%s%s", PREFIX, sessionID);
	remove(&nomepipe[0]);

	sprintf(nomepipe, "%s%s_testo", PREFIX, sessionID);
	remove(&nomepipe[0]);

	sprintf(nomepipe, "%s%s_tipo", PREFIX, sessionID);
	remove(&nomepipe[0]);

	sprintf(nomepipe, "%s%s_risposta", PREFIX, sessionID);
	remove(&nomepipe[0]);
}

// This method creates a named pipe
void create_pipe(char *nomepipe) {
	// set the umask explicitly, you don't know where it's been
	umask(0);

	remove(nomepipe);
	if (mkfifo(nomepipe, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP)) {
		delete_pipes();
		exit(EXIT_FAILURE);
	}
}

// This method writes a string to a file (or a named pipe)
void write_file(char *filename, char *string, int create) {
	int fd;
	int timeout = time(NULL) + 120;
	int written = 0;
	int ret;

	do {
		if (create == 1) {
			fd = open(filename, O_WRONLY | O_CREAT | O_NONBLOCK, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
		}
		else {
			fd = open(filename, O_WRONLY | O_NONBLOCK, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
		}
	} while (time(NULL) <= timeout && fd == -1 && errno == ENXIO);

	if (fd == -1) {
		delete_pipes();
		exit(EXIT_FAILURE);
	}

	// Writes to the file
	do {
		ret = write(fd, string, strlen(string));
		if (ret > 0) written += ret;
		if (ret == -1 && errno != EAGAIN) {
			delete_pipes();
			exit(EXIT_FAILURE);
		}
	} while (time(NULL) <= timeout && written < strlen(string));

	/*
	if (write(fd, string, strlen(string)) != strlen(string)) {
		delete_pipes();
		exit(EXIT_FAILURE);
	}
	*/
	close(fd);
}

// This method reads an input from a file (or a named pipe)
void read_file(char *filename, char **string) {
	int fd;
	char *buf = *string;
	int i = -1;
	int ret;
	int timeout = time(NULL) + 120;

	do {
		fd = open(filename, O_RDONLY | O_NONBLOCK);
	} while (time(NULL) <= timeout && fd == -1 && errno == ENXIO);

	if (fd == -1) {
		delete_pipes();
		exit(EXIT_FAILURE);
	}

	// Read the file until the end of the row or until the maximul length has been read
	do {
		ret = read(fd, buf + i + 1, 1);
		if (ret == 1) i++;
		if (ret == -1 && errno != EAGAIN) {
			delete_pipes();
			exit(EXIT_FAILURE);
		}
	}
	while (time(NULL) <= timeout && (i < 0 || (buf[i] != '\n' && buf[i] != '\0' && i < PAM_MAX_RESP_SIZE)));

	if (buf[i] == '\n') buf[i] = '\0';
	close(fd);
}

// This method creates the named pipes used to communicate with the webservice
void create_pipes() {
	char nomepipe[1024];

	// This file will contain the username of the user to be authenticated
	sprintf(nomepipe, "%s%s", PREFIX, sessionID);
	write_file(&nomepipe[0], username, 1);

	// This pipe contains the text of the question to be presented to the user
	sprintf(nomepipe, "%s%s_testo", PREFIX, sessionID);
	create_pipe(&nomepipe[0]);

	// This pipe contains the type of the question to be presented to the user
	sprintf(nomepipe, "%s%s_tipo", PREFIX, sessionID);
	create_pipe(&nomepipe[0]);

	// This pipe is used to collect the response of the user to the question
	sprintf(nomepipe, "%s%s_risposta", PREFIX, sessionID);
	create_pipe(&nomepipe[0]);
}

// This method rapresents the conversation function to be passed to the PAM library
int pamconv(int num_msg, const struct pam_message **msg, struct pam_response **resp, void *data) {
	char *buf = (char *) calloc(PAM_MAX_RESP_SIZE, sizeof(char));
	char nomepipe[1024];
	int i;

	if (num_msg <= 0 || num_msg > PAM_MAX_NUM_MSG)
		return (PAM_CONV_ERR);

	if ((*resp = calloc(num_msg, sizeof **resp)) == NULL)
		return (PAM_BUF_ERR);

	for (i = 0; i < num_msg; ++i) {
		create_pipes();
	
		resp[i]->resp_retcode = 0;
		resp[i]->resp = NULL;

		// Watch the type of the message and acts accordingly
		switch (msg[i]->msg_style) {
			case PAM_PROMPT_ECHO_OFF:
				sprintf(nomepipe, "%s%s_tipo", PREFIX, sessionID);
				write_file(&nomepipe[0], "PROMPT_ECHO_OFF", 0);
				break;

			case PAM_PROMPT_ECHO_ON:
				sprintf(nomepipe, "%s%s_tipo", PREFIX, sessionID);
				write_file(&nomepipe[0], "PROMPT_ECHO_ON", 0);
				break;

			case PAM_ERROR_MSG:
				sprintf(nomepipe, "%s%s_tipo", PREFIX, sessionID);
				write_file(&nomepipe[0], "ERROR_MSG", 0);
				break;

			case PAM_TEXT_INFO:
				sprintf(nomepipe, "%s%s_tipo", PREFIX, sessionID);
				write_file(&nomepipe[0], "TEXT_INFO", 0);
				break;

			default:
				goto fail;
		}

		sprintf(nomepipe, "%s%s_testo", PREFIX, sessionID);
		write_file(&nomepipe[0], msg[i]->msg, 0);

		// If the message type needs a response from the user, reads it
		sprintf(nomepipe, "%s%s_risposta", PREFIX, sessionID);
		if (msg[i]->msg_style == PAM_PROMPT_ECHO_OFF || msg[i]->msg_style == PAM_PROMPT_ECHO_ON) {
			read_file(&nomepipe[0], &buf);

			resp[i]->resp = strdup(buf);
			if (resp[i]->resp == NULL)
				goto fail;
		}
		// TODO AB
		printf("get response: %s.\n", buf);
		remove(&nomepipe[0]);
	}
	return (PAM_SUCCESS);

fail:
	while (i)
		free(resp[--i]);

	free(*resp);
	*resp = NULL;

	return (PAM_CONV_ERR);
}

// This structure is used to communicate with PAM library
static struct pam_conv conv = {
	pamconv,
	NULL
};

// This method is the method that execute the authentication procedure
int authenticate() {
	pam_handle_t *pamh = NULL;
	int retval = 0;
	int ritorno = 1;
	char path_script[1024];

	// The service to be authenticated against is defined by *service
	retval = pam_start(service, username, &conv, &pamh);
	if (retval != PAM_SUCCESS) {
		return 1;
	}

	// Call the addmessage.pl script that adds a message to the spool of the sms daemon
	sprintf(path_script, "PATH_ADD_MSG=%s/addmessage.pl", PATH_SCRIPT);
	retval = pam_putenv(pamh, path_script);
	if (retval != PAM_SUCCESS) {
		return 1;
	}

	// Execute the real authentication
	retval = pam_authenticate(pamh, 0);
	if (retval == PAM_SUCCESS) {
		ritorno = 0;
	}

	if (pam_end(pamh, retval) != PAM_SUCCESS)
		pamh = NULL;

	return ritorno;
}

// This is the main of the program. Starts the session and tries to authenticate the user.
int main(int argc, char *argv[]) {
	int fd;
	int esito;

	if (argc < 4) {
		fprintf(stderr, "Usage: %s service sessionID username\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	// Initialize the sessionID and username global variables
	service = argv[1];
	sessionID = argv[2];
	username = argv[3];

	// Authenticates the user and clean all the files created
	esito = authenticate();
	delete_pipes();

	return(esito);
}
