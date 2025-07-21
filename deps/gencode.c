#include <sys/time.h>
#include <time.h>
#include <stdio.h>
#include <stddef.h>

#define print_integer_type(file, rval) do {                     \
        rval = -1;                                              \
        fprintf(file, "%s%d", ((rval) < 0 ? "Int" : "UInt"),    \
                (int)(8*sizeof(rval)));                         \
    } while (0)

#define print_integer_field(file, name, rval) do {  \
        fprintf(file, "    %s::", name);            \
        print_integer_type(file, rval);             \
        fprintf(file, "\n");                        \
    } while (0)

int main()
{
    FILE* output = stdout;
    struct timeval tv = {-1, -1};
    struct timespec ts = {-1, -1};
    clockid_t clockid = 0;

    fprintf(output, "struct TimeVal <: TimeStruct\n");
    print_integer_field(output, "sec", tv.tv_sec);
    print_integer_field(output, "usec", tv.tv_usec);
    fprintf(output, "    # Private inner constructor does not normalize arguments.\n");
    fprintf(output, "    global _TimeVal\n");
    fprintf(output, "    _TimeVal(sec::Integer, usec::Integer) = new(sec, usec)\n");
    fprintf(output, "end\n");

    fprintf(output, "\n");

    fprintf(output, "struct TimeSpec <: TimeStruct\n");
    print_integer_field(output, "sec", ts.tv_sec);
    print_integer_field(output, "nsec", ts.tv_nsec);
    fprintf(output, "    # Private inner constructor does not normalize arguments.\n");
    fprintf(output, "    global _TimeSpec\n");
    fprintf(output, "    _TimeSpec(sec::Integer, nsec::Integer) = new(sec, nsec)\n");
    fprintf(output, "end\n");

    fprintf(output, "\n");

    fprintf(output, "const CLOCK_REALTIME = ");
    print_integer_type(output, clockid);
    fprintf(output, "(%ld)\n", (long)CLOCK_REALTIME);

    fprintf(output, "const CLOCK_MONOTONIC = ");
    print_integer_type(output, clockid);
    fprintf(output, "(%ld)\n", (long)CLOCK_MONOTONIC);
    fprintf(output, "\n");

    return 0;
}
