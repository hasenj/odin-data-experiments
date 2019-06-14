package csocket

SOCK_STREAM :: 1;
SOCK_DGRAM :: 2;
SOCK_RAW :: 3;

IPPROTO_TCP :: 6;
IPPROTO_IP :: 0;
IPPROTO_IPV6 :: 41;

SOL_SOCKET :: 0xffff;
SO_REUSEADDR :: 0x0004;

INADDR_ANY :: 0;

// for async
O_NONBLOCK	:: 0x0004;		/* no delay */
O_APPEND	:: 0x0008;		/* set append mode */

F_DUPFD		:: 0;		/* duplicate file descriptor */
F_GETFD		:: 1;		/* get file descriptor flags */
F_SETFD		:: 2;		/* set file descriptor flags */
F_GETFL		:: 3;		/* get file status flags */
F_SETFL		:: 4;		/* set file status flags */
F_GETLK		:: 7;		/* get record locking information */
F_SETLK		:: 8;		/* set record locking information */
F_SETLKW	:: 9;		/* F_SETLK; wait if blocked */