/*
 * pam_retisms.c
 *
 * Author: Andrea Biancini <andrea.biancini@reti.it> (2004/07/11)
 *         Gruppo Reti S.p.A.
 *
 */

#include <stdio.h>
#include <syslog.h>
#include <time.h>

/*
 * here, we make definitions for the externally accessible functions
 * in this file (these definitions are required for static modules
 * but strongly encouraged generally) they are used to instruct the
 * modules include file to define their prototypes.
 */

#define PAM_SM_AUTH
#define PAM_SM_ACCOUNT
#define PAM_SM_SESSION
#define PAM_SM_PASSWORD

/*
 * This definition are for the messages to be written to the users
 */

#include <security/pam_modules.h>
#include <security/_pam_macros.h>

/* --- authentication management functions --- */
#define TOKSYMBOLS "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define SCRIPT_MSG "Script to send messages: "
#define CELL_MSG "Cell Phone number: "
#define TOK_INFO "An alphanumeric token has been sent to your cell phone.\nWrite it back to be authenticated."
#define TOK_MSG "SMS Token: "

int pam_converse(pam_handle_t *pamh, const char *message, char **response, int type) {
	int pam_err = 0;

	char *mresponse = NULL;

	struct pam_conv *conv;
	struct pam_message msg;
	const struct pam_message *msgp;
	struct pam_response *resp;

	pam_err = pam_get_item(pamh, PAM_CONV, (const void **) &conv);

	if (pam_err != PAM_SUCCESS)
		return -1;

	msg.msg_style = type;
	msg.msg = message;
	msgp = &msg;

	resp = NULL;
	pam_err = (*conv->conv)(1, &msgp, &resp, conv->appdata_ptr);

	if (resp != NULL) {
		if (pam_err == PAM_SUCCESS) {
			mresponse = resp->resp;
			pam_err = 0;
		}
		else {
			free(resp->resp);
			pam_err = -1;
		}
		free(resp);
	}

	response[0] = mresponse;
	return pam_err;
}

char *generate_token(int length) {
	char *values = TOKSYMBOLS;
	int mod = strlen(values);
	char *ritorno = calloc(length, sizeof(char));
	int i;

	srand(time(NULL));
	for(i = 0; i < length; i++)
		ritorno[i] = values[rand() % mod];

	return ritorno;
}

PAM_EXTERN
int pam_sm_authenticate(pam_handle_t *pamh, int flags, int argc, const char **argv) {
	int retval;
	const char *user = NULL;
	char *num_cell = NULL;
	char *path_add_message = NULL;
	char command[1024];
	char *sent_token = NULL;
	char *recv_token = NULL;
	int num_char_tok = 20;

	// authentication requires we know who the user wants to be
	retval = pam_get_user(pamh, &user, NULL);
	if (retval != PAM_SUCCESS) {
		syslog(LOG_ALERT, "get user returned error: %s", pam_strerror(pamh, retval));
		return retval;
	}

	if (user == NULL || *user == '\0') {
		return PAM_USER_UNKNOWN;
	}

	// add an SMS message to the spool
	path_add_message = pam_getenv(pamh, "PATH_ADD_MSG");
	if (path_add_message == NULL || *path_add_message == '\0') {
		if (pam_converse(pamh, SCRIPT_MSG, &path_add_message, PAM_PROMPT_ECHO_ON) != 0)
			return PAM_CONV_ERR;
	}

	num_cell = pam_getenv(pamh, "NUM_CELL");
	if (num_cell == NULL || *num_cell == '\0') {
		if (pam_converse(pamh, CELL_MSG, &num_cell, PAM_PROMPT_ECHO_ON) != 0)
			return PAM_CONV_ERR;
	}

	if (pam_converse(pamh, TOK_INFO, &recv_token, PAM_TEXT_INFO) != 0) {
		return PAM_CONV_ERR;
	}
	
	sent_token = generate_token(num_char_tok);
	sprintf(command, "%s \"%s\" \"%s\"", path_add_message, num_cell, sent_token);
	system(command);

	if (pam_converse(pamh, TOK_MSG, &recv_token, PAM_PROMPT_ECHO_ON) != 0) {
		return PAM_CONV_ERR;
	}

	// compare the sent token and the received one and respond correspondingly
	if (strncmp(sent_token, recv_token, num_char_tok) == 0) {
		retval = PAM_SUCCESS;
	}
	else {
		retval = PAM_AUTH_ERR;
	}

	recv_token = NULL;
	num_cell = NULL;
	user = NULL;
	return retval;
}

PAM_EXTERN
int pam_sm_setcred(pam_handle_t *pamh, int flags, int argc, const char **argv) {
	return PAM_SUCCESS;
}

/* --- account management functions --- */

PAM_EXTERN
int pam_sm_acct_mgmt(pam_handle_t *pamh, int flags, int argc, const char **argv) {
	return PAM_SUCCESS;
}

/* --- password management --- */

PAM_EXTERN
int pam_sm_chauthtok(pam_handle_t *pamh, int flags, int argc, const char **argv) {
	return PAM_SUCCESS;
}

/* --- session management --- */

PAM_EXTERN
int pam_sm_open_session(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    return PAM_SUCCESS;
}

PAM_EXTERN
int pam_sm_close_session(pam_handle_t *pamh, int flags, int argc, const char **argv) {
     return PAM_SUCCESS;
}

/* end of module definition */

#ifdef PAM_STATIC

/* static module data */

struct pam_module _pam_permit_modstruct = {
	"pam_retisms",
	pam_sm_authenticate,
	pam_sm_setcred,
	pam_sm_acct_mgmt,
	pam_sm_open_session,
	pam_sm_close_session,
	pam_sm_chauthtok
};

#endif
