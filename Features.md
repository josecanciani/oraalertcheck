# Features #

This is the list of features that currently OraAlertCheck supports:

  * Parse "^ORA-NNNNN" errors and send emails depending on the severity of the error (this will be enhanced as other DBAs contribute with more and more errors).
  * If the errors are on the errors list the alert will provide more information (example: if potential bug then sends a reference to the proper metalink notes).
  * Errors can be costomized accordingly to db version.
  * Only uses korn shell and basic commands like df, compress, tail, cat, echo, etc., so it should be very portable between 