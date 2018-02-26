:- expects_dialect(hprolog).

chop(A,R) :-
  re_replace('[ \\t\\r\\n]+'/g,' ',A,R1),
  re_replace('(^ +| +$)'/g,'',R1,R2),
  atom_string(R,R2).

read_all(Filename,Atom) :- setup_call_cleanup(open(Filename, read, Str),read_file(Str,Lines),close(Str)),
                           atom_codes(Atom,Lines).
read_stream_all(Str,Atom) :- read_file(Str,Lines), atom_codes(Atom,Lines).
read_file(Stream,[])    :- at_end_of_stream(Stream).
read_file(Stream,[X|L]) :- get0(Stream,X), read_file(Stream,L).

all(Filename) :-
    read_all(Filename,Txt), split_string(Txt,"##","##",Lines),!,
    maplist(one,Lines).

one(Data) :-
  split_string(Data,"\n","\r\n",Lines),
  maplist(chop,Lines,[En,Ja|Lines2]),
  re_match('^[0-9]+ *\\. *p',En),
  format('# ~w\n\n--\n\n# ~w\n\n',[En,Ja]),
  split_at(5,Lines2,Lines3,_),
  maplist(data,Lines3),
  writeln('---\n').
one(_).

data(Data) :-
  atom_string(D,Data),
  re_replace('^[a-zA-Z -/\\-‐:-@\\[-`{-~0-9’]+','',D,J),atom_concat(E,J,D),J\='',
  format('--\n\n~w\n\n',[E]),
  format('--\n\n~w\n\n',[J]).
data(_).

:- current_prolog_flag(argv, [Filename]),all(Filename).
:- halt.

