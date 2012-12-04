/* ===================================================================== *
 *  
 * ===================================================================== */
#include<stdio.h>
#include<libpq-fe.h>
/* --------------------------------------------------------------------- */
int main(int argc, char **argv){
  PGconn *conn;
  PGresult *res;

  conn = PQconnectdb("dbname=teamconnected");
  if(PQstatus(conn) != CONNECTION_OK){
    fprintf(stderr, "Connection to database failed: %s", PQerrorMessage(conn));
    PQfinish(conn);
    return 1;
  }

  res = PQexec(conn, "select * from msg_entity limit 2");
  /* res = PQexec(conn, "copy (select * from msg_entity order by id) to '/tmp/wrmupbUOm47'"); */
  switch(PQresultStatus(res)){
    case PGRES_EMPTY_QUERY:
      break;
    case PGRES_TUPLES_OK:
      {
        int n = PQnfields(res);
        int i, j;
        for(i = 0; i < n; i++){
          printf("%-15s", PQfname(res, i));
        }
        printf("\n\n");
        for(i = 0; i < PQntuples(res); i++){
          for(j = 0; j < n; j++){
            printf("%-15s", PQgetvalue(res, i, j));
          }
          printf("\n");
        }
      }
      break;
    case PGRES_COPY_OUT:
    case PGRES_COPY_IN:
    case PGRES_COPY_BOTH:
    case PGRES_COMMAND_OK:
      break;
    case PGRES_BAD_RESPONSE:
      fprintf(stderr, "Server is speaking an alien language: %s", PQerrorMessage(conn));
      PQclear(res);
      PQfinish(conn);
      return 1;
    case PGRES_NONFATAL_ERROR:
    case PGRES_FATAL_ERROR:
      fprintf(stderr, "PQexec failed: %s", PQerrorMessage(conn));
      PQclear(res);
      PQfinish(conn);
      return 1;
  }
  PQclear(res);

  PQfinish(conn);
  return 0;
}
/* ===================================================================== *
 * vim modeline                                                          *
 * vim:se fdm=expr foldexpr=getline(v\:lnum)=~'^\\S.*{'?'>1'\:1:         *
 * ===================================================================== */
