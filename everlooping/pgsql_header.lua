#!/usr/bin/env luajit

local ffi = require('ffi')

module(...)

ffi.cdef[[
typedef long unsigned int size_t;

typedef unsigned char __u_char;
typedef unsigned short int __u_short;
typedef unsigned int __u_int;
typedef unsigned long int __u_long;

typedef signed char __int8_t;
typedef unsigned char __uint8_t;
typedef signed short int __int16_t;
typedef unsigned short int __uint16_t;
typedef signed int __int32_t;
typedef unsigned int __uint32_t;

typedef signed long int __int64_t;
typedef unsigned long int __uint64_t;

typedef long int __quad_t;
typedef unsigned long int __u_quad_t;

typedef unsigned long int __dev_t;
typedef unsigned int __uid_t;
typedef unsigned int __gid_t;
typedef unsigned long int __ino_t;
typedef unsigned long int __ino64_t;
typedef unsigned int __mode_t;
typedef unsigned long int __nlink_t;
typedef long int __off_t;
typedef long int __off64_t;
typedef int __pid_t;
typedef struct { int __val[2]; } __fsid_t;
typedef long int __clock_t;
typedef unsigned long int __rlim_t;
typedef unsigned long int __rlim64_t;
typedef unsigned int __id_t;
typedef long int __time_t;
typedef unsigned int __useconds_t;
typedef long int __suseconds_t;

typedef int __daddr_t;
typedef long int __swblk_t;
typedef int __key_t;

typedef int __clockid_t;

typedef void * __timer_t;

typedef long int __blksize_t;

typedef long int __blkcnt_t;
typedef long int __blkcnt64_t;

typedef unsigned long int __fsblkcnt_t;
typedef unsigned long int __fsblkcnt64_t;

typedef unsigned long int __fsfilcnt_t;
typedef unsigned long int __fsfilcnt64_t;

typedef long int __fsword_t;

typedef long int __ssize_t;

typedef long int __syscall_slong_t;

typedef unsigned long int __syscall_ulong_t;

typedef __off64_t __loff_t;
typedef __quad_t *__qaddr_t;
typedef char *__caddr_t;

typedef long int __intptr_t;

typedef unsigned int __socklen_t;
struct _IO_FILE;

typedef struct _IO_FILE FILE;

typedef struct _IO_FILE __FILE;

typedef struct
{
  int __count;
  union
  {

    unsigned int __wch;

    char __wchb[4];
  } __value;
} __mbstate_t;

typedef struct
{
  __off_t __pos;
  __mbstate_t __state;
} _G_fpos_t;
typedef struct
{
  __off64_t __pos;
  __mbstate_t __state;
} _G_fpos64_t;
typedef int _G_int16_t __attribute__ ((__mode__ (__HI__)));
typedef int _G_int32_t __attribute__ ((__mode__ (__SI__)));
typedef unsigned int _G_uint16_t __attribute__ ((__mode__ (__HI__)));
typedef unsigned int _G_uint32_t __attribute__ ((__mode__ (__SI__)));
typedef __builtin_va_list __gnuc_va_list;
struct _IO_jump_t; struct _IO_FILE;
typedef void _IO_lock_t;

struct _IO_marker {
  struct _IO_marker *_next;
  struct _IO_FILE *_sbuf;

  int _pos;
};

enum __codecvt_result
{
  __codecvt_ok,
  __codecvt_partial,
  __codecvt_error,
  __codecvt_noconv
};
struct _IO_FILE {
  int _flags;

  char* _IO_read_ptr;
  char* _IO_read_end;
  char* _IO_read_base;
  char* _IO_write_base;
  char* _IO_write_ptr;
  char* _IO_write_end;
  char* _IO_buf_base;
  char* _IO_buf_end;

  char *_IO_save_base;
  char *_IO_backup_base;
  char *_IO_save_end;

  struct _IO_marker *_markers;

  struct _IO_FILE *_chain;

  int _fileno;

  int _flags2;

  __off_t _old_offset;

  unsigned short _cur_column;
  signed char _vtable_offset;
  char _shortbuf[1];

  _IO_lock_t *_lock;
  __off64_t _offset;
  void *__pad1;
  void *__pad2;
  void *__pad3;
  void *__pad4;
  size_t __pad5;

  int _mode;

  char _unused2[15 * sizeof (int) - 4 * sizeof (void *) - sizeof (size_t)];

};

typedef struct _IO_FILE _IO_FILE;

struct _IO_FILE_plus;

extern struct _IO_FILE_plus _IO_2_1_stdin_;
extern struct _IO_FILE_plus _IO_2_1_stdout_;
extern struct _IO_FILE_plus _IO_2_1_stderr_;
typedef __ssize_t __io_read_fn (void *__cookie, char *__buf, size_t __nbytes);

typedef __ssize_t __io_write_fn (void *__cookie, const char *__buf,
     size_t __n);

typedef int __io_seek_fn (void *__cookie, __off64_t *__pos, int __w);

typedef int __io_close_fn (void *__cookie);
extern int __underflow (_IO_FILE *);
extern int __uflow (_IO_FILE *);
extern int __overflow (_IO_FILE *, int);
extern int _IO_getc (_IO_FILE *__fp);
extern int _IO_putc (int __c, _IO_FILE *__fp);
extern int _IO_feof (_IO_FILE *__fp) __attribute__ ((__nothrow__ , __leaf__));
extern int _IO_ferror (_IO_FILE *__fp) __attribute__ ((__nothrow__ , __leaf__));

extern int _IO_peekc_locked (_IO_FILE *__fp);

extern void _IO_flockfile (_IO_FILE *) __attribute__ ((__nothrow__ , __leaf__));
extern void _IO_funlockfile (_IO_FILE *) __attribute__ ((__nothrow__ , __leaf__));
extern int _IO_ftrylockfile (_IO_FILE *) __attribute__ ((__nothrow__ , __leaf__));
extern int _IO_vfscanf (_IO_FILE * __restrict, const char * __restrict,
   __gnuc_va_list, int *__restrict);
extern int _IO_vfprintf (_IO_FILE *__restrict, const char *__restrict,
    __gnuc_va_list);
extern __ssize_t _IO_padn (_IO_FILE *, int, __ssize_t);
extern size_t _IO_sgetn (_IO_FILE *, void *, size_t);

extern __off64_t _IO_seekoff (_IO_FILE *, __off64_t, int, int);
extern __off64_t _IO_seekpos (_IO_FILE *, __off64_t, int);

extern void _IO_free_backup_area (_IO_FILE *) __attribute__ ((__nothrow__ , __leaf__));

typedef __gnuc_va_list va_list;
typedef __off_t off_t;
typedef __ssize_t ssize_t;

typedef _G_fpos_t fpos_t;

extern struct _IO_FILE *stdin;
extern struct _IO_FILE *stdout;
extern struct _IO_FILE *stderr;

extern int remove (const char *__filename) __attribute__ ((__nothrow__ , __leaf__));

extern int rename (const char *__old, const char *__new) __attribute__ ((__nothrow__ , __leaf__));

extern int renameat (int __oldfd, const char *__old, int __newfd,
       const char *__new) __attribute__ ((__nothrow__ , __leaf__));

extern FILE *tmpfile (void) ;
extern char *tmpnam (char *__s) __attribute__ ((__nothrow__ , __leaf__)) ;

extern char *tmpnam_r (char *__s) __attribute__ ((__nothrow__ , __leaf__)) ;
extern char *tempnam (const char *__dir, const char *__pfx)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__malloc__)) ;

extern int fclose (FILE *__stream);

extern int fflush (FILE *__stream);

extern int fflush_unlocked (FILE *__stream);

extern FILE *fopen (const char *__restrict __filename,
      const char *__restrict __modes) ;

extern FILE *freopen (const char *__restrict __filename,
        const char *__restrict __modes,
        FILE *__restrict __stream) ;

extern FILE *fdopen (int __fd, const char *__modes) __attribute__ ((__nothrow__ , __leaf__)) ;
extern FILE *fmemopen (void *__s, size_t __len, const char *__modes)
  __attribute__ ((__nothrow__ , __leaf__)) ;

extern FILE *open_memstream (char **__bufloc, size_t *__sizeloc) __attribute__ ((__nothrow__ , __leaf__)) ;

extern void setbuf (FILE *__restrict __stream, char *__restrict __buf) __attribute__ ((__nothrow__ , __leaf__));

extern int setvbuf (FILE *__restrict __stream, char *__restrict __buf,
      int __modes, size_t __n) __attribute__ ((__nothrow__ , __leaf__));

extern void setbuffer (FILE *__restrict __stream, char *__restrict __buf,
         size_t __size) __attribute__ ((__nothrow__ , __leaf__));

extern void setlinebuf (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__));

extern int fprintf (FILE *__restrict __stream,
      const char *__restrict __format, ...);

extern int printf (const char *__restrict __format, ...);

extern int sprintf (char *__restrict __s,
      const char *__restrict __format, ...) __attribute__ ((__nothrow__));

extern int vfprintf (FILE *__restrict __s, const char *__restrict __format,
       __gnuc_va_list __arg);

extern int vprintf (const char *__restrict __format, __gnuc_va_list __arg);

extern int vsprintf (char *__restrict __s, const char *__restrict __format,
       __gnuc_va_list __arg) __attribute__ ((__nothrow__));

extern int snprintf (char *__restrict __s, size_t __maxlen,
       const char *__restrict __format, ...)
     __attribute__ ((__nothrow__)) __attribute__ ((__format__ (__printf__, 3, 4)));

extern int vsnprintf (char *__restrict __s, size_t __maxlen,
        const char *__restrict __format, __gnuc_va_list __arg)
     __attribute__ ((__nothrow__)) __attribute__ ((__format__ (__printf__, 3, 0)));

extern int vdprintf (int __fd, const char *__restrict __fmt,
       __gnuc_va_list __arg)
     __attribute__ ((__format__ (__printf__, 2, 0)));
extern int dprintf (int __fd, const char *__restrict __fmt, ...)
     __attribute__ ((__format__ (__printf__, 2, 3)));

extern int fscanf (FILE *__restrict __stream,
     const char *__restrict __format, ...) ;

extern int scanf (const char *__restrict __format, ...) ;

extern int sscanf (const char *__restrict __s,
     const char *__restrict __format, ...) __attribute__ ((__nothrow__ , __leaf__));
extern int fscanf (FILE *__restrict __stream, const char *__restrict __format, ...) __asm__ ("" "__isoc99_fscanf")

                               ;
extern int scanf (const char *__restrict __format, ...) __asm__ ("" "__isoc99_scanf")
                              ;
extern int sscanf (const char *__restrict __s, const char *__restrict __format, ...) __asm__ ("" "__isoc99_sscanf") __attribute__ ((__nothrow__ , __leaf__))

                      ;

extern int vfscanf (FILE *__restrict __s, const char *__restrict __format,
      __gnuc_va_list __arg)
     __attribute__ ((__format__ (__scanf__, 2, 0))) ;

extern int vscanf (const char *__restrict __format, __gnuc_va_list __arg)
     __attribute__ ((__format__ (__scanf__, 1, 0))) ;

extern int vsscanf (const char *__restrict __s,
      const char *__restrict __format, __gnuc_va_list __arg)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__format__ (__scanf__, 2, 0)));
extern int vfscanf (FILE *__restrict __s, const char *__restrict __format, __gnuc_va_list __arg) __asm__ ("" "__isoc99_vfscanf")

     __attribute__ ((__format__ (__scanf__, 2, 0))) ;
extern int vscanf (const char *__restrict __format, __gnuc_va_list __arg) __asm__ ("" "__isoc99_vscanf")

     __attribute__ ((__format__ (__scanf__, 1, 0))) ;
extern int vsscanf (const char *__restrict __s, const char *__restrict __format, __gnuc_va_list __arg) __asm__ ("" "__isoc99_vsscanf") __attribute__ ((__nothrow__ , __leaf__))

     __attribute__ ((__format__ (__scanf__, 2, 0)));

extern int fgetc (FILE *__stream);
extern int getc (FILE *__stream);

extern int getchar (void);

extern int getc_unlocked (FILE *__stream);
extern int getchar_unlocked (void);
extern int fgetc_unlocked (FILE *__stream);

extern int fputc (int __c, FILE *__stream);
extern int putc (int __c, FILE *__stream);

extern int putchar (int __c);

extern int fputc_unlocked (int __c, FILE *__stream);

extern int putc_unlocked (int __c, FILE *__stream);
extern int putchar_unlocked (int __c);

extern int getw (FILE *__stream);

extern int putw (int __w, FILE *__stream);

extern char *fgets (char *__restrict __s, int __n, FILE *__restrict __stream)
     ;
extern char *gets (char *__s) __attribute__ ((__deprecated__));

extern __ssize_t __getdelim (char **__restrict __lineptr,
          size_t *__restrict __n, int __delimiter,
          FILE *__restrict __stream) ;
extern __ssize_t getdelim (char **__restrict __lineptr,
        size_t *__restrict __n, int __delimiter,
        FILE *__restrict __stream) ;

extern __ssize_t getline (char **__restrict __lineptr,
       size_t *__restrict __n,
       FILE *__restrict __stream) ;

extern int fputs (const char *__restrict __s, FILE *__restrict __stream);

extern int puts (const char *__s);

extern int ungetc (int __c, FILE *__stream);

extern size_t fread (void *__restrict __ptr, size_t __size,
       size_t __n, FILE *__restrict __stream) ;

extern size_t fwrite (const void *__restrict __ptr, size_t __size,
        size_t __n, FILE *__restrict __s);

extern size_t fread_unlocked (void *__restrict __ptr, size_t __size,
         size_t __n, FILE *__restrict __stream) ;
extern size_t fwrite_unlocked (const void *__restrict __ptr, size_t __size,
          size_t __n, FILE *__restrict __stream);

extern int fseek (FILE *__stream, long int __off, int __whence);

extern long int ftell (FILE *__stream) ;

extern void rewind (FILE *__stream);

extern int fseeko (FILE *__stream, __off_t __off, int __whence);

extern __off_t ftello (FILE *__stream) ;

extern int fgetpos (FILE *__restrict __stream, fpos_t *__restrict __pos);

extern int fsetpos (FILE *__stream, const fpos_t *__pos);

extern void clearerr (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__));

extern int feof (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;

extern int ferror (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;

extern void clearerr_unlocked (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__));
extern int feof_unlocked (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;
extern int ferror_unlocked (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;

extern void perror (const char *__s);

extern int sys_nerr;
extern const char *const sys_errlist[];

extern int fileno (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;

extern int fileno_unlocked (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;
extern FILE *popen (const char *__command, const char *__modes) ;

extern int pclose (FILE *__stream);

extern char *ctermid (char *__s) __attribute__ ((__nothrow__ , __leaf__));
extern void flockfile (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__));

extern int ftrylockfile (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__)) ;

extern void funlockfile (FILE *__stream) __attribute__ ((__nothrow__ , __leaf__));

typedef unsigned int Oid;
typedef enum
{

 CONNECTION_OK,
 CONNECTION_BAD,

 CONNECTION_STARTED,
 CONNECTION_MADE,
 CONNECTION_AWAITING_RESPONSE,

 CONNECTION_AUTH_OK,

 CONNECTION_SETENV,
 CONNECTION_SSL_STARTUP,
 CONNECTION_NEEDED
} ConnStatusType;

typedef enum
{
 PGRES_POLLING_FAILED = 0,
 PGRES_POLLING_READING,
 PGRES_POLLING_WRITING,
 PGRES_POLLING_OK,
 PGRES_POLLING_ACTIVE

} PostgresPollingStatusType;

typedef enum
{
 PGRES_EMPTY_QUERY = 0,
 PGRES_COMMAND_OK,

 PGRES_TUPLES_OK,

 PGRES_COPY_OUT,
 PGRES_COPY_IN,
 PGRES_BAD_RESPONSE,

 PGRES_NONFATAL_ERROR,
 PGRES_FATAL_ERROR,
 PGRES_COPY_BOTH
} ExecStatusType;

typedef enum
{
 PQTRANS_IDLE,
 PQTRANS_ACTIVE,
 PQTRANS_INTRANS,
 PQTRANS_INERROR,
 PQTRANS_UNKNOWN
} PGTransactionStatusType;

typedef enum
{
 PQERRORS_TERSE,
 PQERRORS_DEFAULT,
 PQERRORS_VERBOSE
} PGVerbosity;

typedef enum
{
 PQPING_OK,
 PQPING_REJECT,
 PQPING_NO_RESPONSE,
 PQPING_NO_ATTEMPT
} PGPing;

typedef struct pg_conn PGconn;

typedef struct pg_result PGresult;

typedef struct pg_cancel PGcancel;

typedef struct pgNotify
{
 char *relname;
 int be_pid;
 char *extra;

 struct pgNotify *next;
} PGnotify;

typedef void (*PQnoticeReceiver) (void *arg, const PGresult *res);
typedef void (*PQnoticeProcessor) (void *arg, const char *message);

typedef char pqbool;

typedef struct _PQprintOpt
{
 pqbool header;
 pqbool align;
 pqbool standard;
 pqbool html3;
 pqbool expanded;
 pqbool pager;
 char *fieldSep;
 char *tableOpt;
 char *caption;
 char **fieldName;

} PQprintOpt;
typedef struct _PQconninfoOption
{
 char *keyword;
 char *envvar;
 char *compiled;
 char *val;
 char *label;
 char *dispchar;

 int dispsize;
} PQconninfoOption;

typedef struct
{
 int len;
 int isint;
 union
 {
  int *ptr;
  int integer;
 } u;
} PQArgBlock;

typedef struct pgresAttDesc
{
 char *name;
 Oid tableid;
 int columnid;
 int format;
 Oid typid;
 int typlen;
 int atttypmod;
} PGresAttDesc;
extern PGconn *PQconnectStart(const char *conninfo);
extern PGconn *PQconnectStartParams(const char **keywords,
      const char **values, int expand_dbname);
extern PostgresPollingStatusType PQconnectPoll(PGconn *conn);

extern PGconn *PQconnectdb(const char *conninfo);
extern PGconn *PQconnectdbParams(const char **keywords,
      const char **values, int expand_dbname);
extern PGconn *PQsetdbLogin(const char *pghost, const char *pgport,
    const char *pgoptions, const char *pgtty,
    const char *dbName,
    const char *login, const char *pwd);

extern void PQfinish(PGconn *conn);

extern PQconninfoOption *PQconndefaults(void);

extern PQconninfoOption *PQconninfoParse(const char *conninfo, char **errmsg);

extern void PQconninfoFree(PQconninfoOption *connOptions);

extern int PQresetStart(PGconn *conn);
extern PostgresPollingStatusType PQresetPoll(PGconn *conn);

extern void PQreset(PGconn *conn);

extern PGcancel *PQgetCancel(PGconn *conn);

extern void PQfreeCancel(PGcancel *cancel);

extern int PQcancel(PGcancel *cancel, char *errbuf, int errbufsize);

extern int PQrequestCancel(PGconn *conn);

extern char *PQdb(const PGconn *conn);
extern char *PQuser(const PGconn *conn);
extern char *PQpass(const PGconn *conn);
extern char *PQhost(const PGconn *conn);
extern char *PQport(const PGconn *conn);
extern char *PQtty(const PGconn *conn);
extern char *PQoptions(const PGconn *conn);
extern ConnStatusType PQstatus(const PGconn *conn);
extern PGTransactionStatusType PQtransactionStatus(const PGconn *conn);
extern const char *PQparameterStatus(const PGconn *conn,
      const char *paramName);
extern int PQprotocolVersion(const PGconn *conn);
extern int PQserverVersion(const PGconn *conn);
extern char *PQerrorMessage(const PGconn *conn);
extern int PQsocket(const PGconn *conn);
extern int PQbackendPID(const PGconn *conn);
extern int PQconnectionNeedsPassword(const PGconn *conn);
extern int PQconnectionUsedPassword(const PGconn *conn);
extern int PQclientEncoding(const PGconn *conn);
extern int PQsetClientEncoding(PGconn *conn, const char *encoding);

extern void *PQgetssl(PGconn *conn);

extern void PQinitSSL(int do_init);

extern void PQinitOpenSSL(int do_ssl, int do_crypto);

extern PGVerbosity PQsetErrorVerbosity(PGconn *conn, PGVerbosity verbosity);

extern void PQtrace(PGconn *conn, FILE *debug_port);
extern void PQuntrace(PGconn *conn);

extern PQnoticeReceiver PQsetNoticeReceiver(PGconn *conn,
     PQnoticeReceiver proc,
     void *arg);
extern PQnoticeProcessor PQsetNoticeProcessor(PGconn *conn,
      PQnoticeProcessor proc,
      void *arg);
typedef void (*pgthreadlock_t) (int acquire);

extern pgthreadlock_t PQregisterThreadLock(pgthreadlock_t newhandler);

extern PGresult *PQexec(PGconn *conn, const char *query);
extern PGresult *PQexecParams(PGconn *conn,
    const char *command,
    int nParams,
    const Oid *paramTypes,
    const char *const * paramValues,
    const int *paramLengths,
    const int *paramFormats,
    int resultFormat);
extern PGresult *PQprepare(PGconn *conn, const char *stmtName,
    const char *query, int nParams,
    const Oid *paramTypes);
extern PGresult *PQexecPrepared(PGconn *conn,
      const char *stmtName,
      int nParams,
      const char *const * paramValues,
      const int *paramLengths,
      const int *paramFormats,
      int resultFormat);

extern int PQsendQuery(PGconn *conn, const char *query);
extern int PQsendQueryParams(PGconn *conn,
      const char *command,
      int nParams,
      const Oid *paramTypes,
      const char *const * paramValues,
      const int *paramLengths,
      const int *paramFormats,
      int resultFormat);
extern int PQsendPrepare(PGconn *conn, const char *stmtName,
     const char *query, int nParams,
     const Oid *paramTypes);
extern int PQsendQueryPrepared(PGconn *conn,
     const char *stmtName,
     int nParams,
     const char *const * paramValues,
     const int *paramLengths,
     const int *paramFormats,
     int resultFormat);
extern PGresult *PQgetResult(PGconn *conn);

extern int PQisBusy(PGconn *conn);
extern int PQconsumeInput(PGconn *conn);

extern PGnotify *PQnotifies(PGconn *conn);

extern int PQputCopyData(PGconn *conn, const char *buffer, int nbytes);
extern int PQputCopyEnd(PGconn *conn, const char *errormsg);
extern int PQgetCopyData(PGconn *conn, char **buffer, int async);

extern int PQgetline(PGconn *conn, char *string, int length);
extern int PQputline(PGconn *conn, const char *string);
extern int PQgetlineAsync(PGconn *conn, char *buffer, int bufsize);
extern int PQputnbytes(PGconn *conn, const char *buffer, int nbytes);
extern int PQendcopy(PGconn *conn);

extern int PQsetnonblocking(PGconn *conn, int arg);
extern int PQisnonblocking(const PGconn *conn);
extern int PQisthreadsafe(void);
extern PGPing PQping(const char *conninfo);
extern PGPing PQpingParams(const char **keywords,
    const char **values, int expand_dbname);

extern int PQflush(PGconn *conn);

extern PGresult *PQfn(PGconn *conn,
  int fnid,
  int *result_buf,
  int *result_len,
  int result_is_int,
  const PQArgBlock *args,
  int nargs);

extern ExecStatusType PQresultStatus(const PGresult *res);
extern char *PQresStatus(ExecStatusType status);
extern char *PQresultErrorMessage(const PGresult *res);
extern char *PQresultErrorField(const PGresult *res, int fieldcode);
extern int PQntuples(const PGresult *res);
extern int PQnfields(const PGresult *res);
extern int PQbinaryTuples(const PGresult *res);
extern char *PQfname(const PGresult *res, int field_num);
extern int PQfnumber(const PGresult *res, const char *field_name);
extern Oid PQftable(const PGresult *res, int field_num);
extern int PQftablecol(const PGresult *res, int field_num);
extern int PQfformat(const PGresult *res, int field_num);
extern Oid PQftype(const PGresult *res, int field_num);
extern int PQfsize(const PGresult *res, int field_num);
extern int PQfmod(const PGresult *res, int field_num);
extern char *PQcmdStatus(PGresult *res);
extern char *PQoidStatus(const PGresult *res);
extern Oid PQoidValue(const PGresult *res);
extern char *PQcmdTuples(PGresult *res);
extern char *PQgetvalue(const PGresult *res, int tup_num, int field_num);
extern int PQgetlength(const PGresult *res, int tup_num, int field_num);
extern int PQgetisnull(const PGresult *res, int tup_num, int field_num);
extern int PQnparams(const PGresult *res);
extern Oid PQparamtype(const PGresult *res, int param_num);

extern PGresult *PQdescribePrepared(PGconn *conn, const char *stmt);
extern PGresult *PQdescribePortal(PGconn *conn, const char *portal);
extern int PQsendDescribePrepared(PGconn *conn, const char *stmt);
extern int PQsendDescribePortal(PGconn *conn, const char *portal);

extern void PQclear(PGresult *res);

extern void PQfreemem(void *ptr);
extern PGresult *PQmakeEmptyPGresult(PGconn *conn, ExecStatusType status);
extern PGresult *PQcopyResult(const PGresult *src, int flags);
extern int PQsetResultAttrs(PGresult *res, int numAttributes, PGresAttDesc *attDescs);
extern void *PQresultAlloc(PGresult *res, size_t nBytes);
extern int PQsetvalue(PGresult *res, int tup_num, int field_num, char *value, int len);

extern size_t PQescapeStringConn(PGconn *conn,
       char *to, const char *from, size_t length,
       int *error);
extern char *PQescapeLiteral(PGconn *conn, const char *str, size_t len);
extern char *PQescapeIdentifier(PGconn *conn, const char *str, size_t len);
extern unsigned char *PQescapeByteaConn(PGconn *conn,
      const unsigned char *from, size_t from_length,
      size_t *to_length);
extern unsigned char *PQunescapeBytea(const unsigned char *strtext,
    size_t *retbuflen);

extern size_t PQescapeString(char *to, const char *from, size_t length);
extern unsigned char *PQescapeBytea(const unsigned char *from, size_t from_length,
     size_t *to_length);

extern void
PQprint(FILE *fout,
  const PGresult *res,
  const PQprintOpt *ps);

extern void
PQdisplayTuples(const PGresult *res,
    FILE *fp,
    int fillAlign,
    const char *fieldSep,
    int printHeader,
    int quiet);

extern void
PQprintTuples(const PGresult *res,
     FILE *fout,
     int printAttName,
     int terseOutput,
     int width);

extern int lo_open(PGconn *conn, Oid lobjId, int mode);
extern int lo_close(PGconn *conn, int fd);
extern int lo_read(PGconn *conn, int fd, char *buf, size_t len);
extern int lo_write(PGconn *conn, int fd, const char *buf, size_t len);
extern int lo_lseek(PGconn *conn, int fd, int offset, int whence);
extern Oid lo_creat(PGconn *conn, int mode);
extern Oid lo_create(PGconn *conn, Oid lobjId);
extern int lo_tell(PGconn *conn, int fd);
extern int lo_truncate(PGconn *conn, int fd, size_t len);
extern int lo_unlink(PGconn *conn, Oid lobjId);
extern Oid lo_import(PGconn *conn, const char *filename);
extern Oid lo_import_with_oid(PGconn *conn, const char *filename, Oid lobjId);
extern int lo_export(PGconn *conn, Oid lobjId, const char *filename);

extern int PQlibVersion(void);

extern int PQmblen(const char *s, int encoding);

extern int PQdsplen(const char *s, int encoding);

extern int PQenv2encoding(void);

extern char *PQencryptPassword(const char *passwd, const char *user);

extern int pg_char_to_encoding(const char *name);
extern const char *pg_encoding_to_char(int encoding);
extern int pg_valid_server_encoding_id(int encoding);
]]
