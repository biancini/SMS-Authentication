SMS Authentication
==================

Prototype of a mechansim to authenticate users using a token sent via SMS.
Within this project a PAM module has been realized to authenticate users with SMS
tokens. The various components have been distributed as RPMs.
Copyright, 2004-2012, Andrea Biancini

The main components are:


PAM SMS
-------

The pamsms PAM module is a module for PAM which is able to authenticate
a user using his mobile phone.
This module sends a random alfanumerical token via SMS to the cell-phone
of the user to be authenticated and then waits for the user to communicate
this token back. It consider the user authenticated only when the right
token has been communicated back.


SMS Gateway
-----------

SMS Gateway is a program which controls a GSM modem (connected to serial port)
and uses it to send and receive SMS messages to GSM devices.
This program creates a spool directory where you can put files rapresenting
an SMS to be sent.
It also listens to messages incoming and if one message is received it could
perform some particolar action accordingly to the current configuration.


SMS Webservice
--------------

SMS Webservice is a program which implements a wrapper to the PAM authentication
mechanism. It makes possibile to authenticate against PAM via a web-service
interface.
It also supports authentication via the GSM cell-phone.


The Latest Version
==================

In order to know which is the latest version of this software you
should contact Gruppo Reti S.p.A. directly or visit its web site:
http://www.reti.it/.


Installation
============

This software is distributed as an RPM file for a RedHat Linux or Fedora
Linux platforms.


