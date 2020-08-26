part of bindings;
// ignore_for_file: non_constant_identifier_names, camel_case_types, unnecessary_brace_in_string_interps, unused_element

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.

abstract class EPOLL_EVENTS {
  static const int EPOLLIN = 1;
  static const int EPOLLPRI = 2;
  static const int EPOLLOUT = 4;
  static const int EPOLLRDNORM = 64;
  static const int EPOLLRDBAND = 128;
  static const int EPOLLWRNORM = 256;
  static const int EPOLLWRBAND = 512;
  static const int EPOLLMSG = 1024;
  static const int EPOLLERR = 8;
  static const int EPOLLHUP = 16;
  static const int EPOLLRDHUP = 8192;
  static const int EPOLLEXCLUSIVE = 268435456;
  static const int EPOLLWAKEUP = 536870912;
  static const int EPOLLONESHOT = 1073741824;
  static const int EPOLLET = -2147483648;
}

const int EPOLLIN = 1;

const int EPOLLPRI = 2;

const int EPOLLOUT = 4;

const int EPOLLRDNORM = 64;

const int EPOLLRDBAND = 128;

const int EPOLLWRNORM = 256;

const int EPOLLWRBAND = 512;

const int EPOLLMSG = 1024;

const int EPOLLERR = 8;

const int EPOLLHUP = 16;

const int EPOLLRDHUP = 8192;

const int EPOLLEXCLUSIVE = 268435456;

const int EPOLLWAKEUP = 536870912;

const int EPOLLONESHOT = 1073741824;

const int EPOLLET = 2147483648;

const int EPOLL_CTL_ADD = 1;

const int EPOLL_CTL_DEL = 2;

const int EPOLL_CTL_MOD = 3;

const int EDEADLK = 35;

const int ENAMETOOLONG = 36;

const int ENOLCK = 37;

const int ENOSYS = 38;

const int ENOTEMPTY = 39;

const int ELOOP = 40;

const int EWOULDBLOCK = 11;

const int ENOMSG = 42;

const int EIDRM = 43;

const int ECHRNG = 44;

const int EL2NSYNC = 45;

const int EL3HLT = 46;

const int EL3RST = 47;

const int ELNRNG = 48;

const int EUNATCH = 49;

const int ENOCSI = 50;

const int EL2HLT = 51;

const int EBADE = 52;

const int EBADR = 53;

const int EXFULL = 54;

const int ENOANO = 55;

const int EBADRQC = 56;

const int EBADSLT = 57;

const int EDEADLOCK = 35;

const int EBFONT = 59;

const int ENOSTR = 60;

const int ENODATA = 61;

const int ETIME = 62;

const int ENOSR = 63;

const int ENONET = 64;

const int ENOPKG = 65;

const int EREMOTE = 66;

const int ENOLINK = 67;

const int EADV = 68;

const int ESRMNT = 69;

const int ECOMM = 70;

const int EPROTO = 71;

const int EMULTIHOP = 72;

const int EDOTDOT = 73;

const int EBADMSG = 74;

const int EOVERFLOW = 75;

const int ENOTUNIQ = 76;

const int EBADFD = 77;

const int EREMCHG = 78;

const int ELIBACC = 79;

const int ELIBBAD = 80;

const int ELIBSCN = 81;

const int ELIBMAX = 82;

const int ELIBEXEC = 83;

const int EILSEQ = 84;

const int ERESTART = 85;

const int ESTRPIPE = 86;

const int EUSERS = 87;

const int ENOTSOCK = 88;

const int EDESTADDRREQ = 89;

const int EMSGSIZE = 90;

const int EPROTOTYPE = 91;

const int ENOPROTOOPT = 92;

const int EPROTONOSUPPORT = 93;

const int ESOCKTNOSUPPORT = 94;

const int EOPNOTSUPP = 95;

const int EPFNOSUPPORT = 96;

const int EAFNOSUPPORT = 97;

const int EADDRINUSE = 98;

const int EADDRNOTAVAIL = 99;

const int ENETDOWN = 100;

const int ENETUNREACH = 101;

const int ENETRESET = 102;

const int ECONNABORTED = 103;

const int ECONNRESET = 104;

const int ENOBUFS = 105;

const int EISCONN = 106;

const int ENOTCONN = 107;

const int ESHUTDOWN = 108;

const int ETOOMANYREFS = 109;

const int ETIMEDOUT = 110;

const int ECONNREFUSED = 111;

const int EHOSTDOWN = 112;

const int EHOSTUNREACH = 113;

const int EALREADY = 114;

const int EINPROGRESS = 115;

const int ESTALE = 116;

const int EUCLEAN = 117;

const int ENOTNAM = 118;

const int ENAVAIL = 119;

const int EISNAM = 120;

const int EREMOTEIO = 121;

const int EDQUOT = 122;

const int ENOMEDIUM = 123;

const int EMEDIUMTYPE = 124;

const int ECANCELED = 125;

const int ENOKEY = 126;

const int EKEYEXPIRED = 127;

const int EKEYREVOKED = 128;

const int EKEYREJECTED = 129;

const int EOWNERDEAD = 130;

const int ENOTRECOVERABLE = 131;

const int ERFKILL = 132;

const int EHWPOISON = 133;

const int ENOTSUP = 95;

const int O_ACCMODE = 3;

const int O_RDONLY = 0;

const int O_WRONLY = 1;

const int O_RDWR = 2;

const int O_CREAT = 64;

const int O_EXCL = 128;

const int O_NOCTTY = 256;

const int O_TRUNC = 512;

const int O_APPEND = 1024;

const int O_NONBLOCK = 2048;

const int O_NDELAY = 2048;

const int O_SYNC = 1052672;

const int O_FSYNC = 1052672;

const int O_ASYNC = 8192;

const int O_DIRECTORY = 65536;

const int O_NOFOLLOW = 131072;

const int O_CLOEXEC = 524288;

const int O_DSYNC = 4096;

const int O_RSYNC = 1052672;
