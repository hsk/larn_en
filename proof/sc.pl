:- use_module(library(http/http_open)).
% 英語例文 スクレイピング on prolog

chop(A,R) :- re_replace('[ \\t\\r\\n]+'/g,' ',A,R1), re_replace('(^ +| +$)'/g,'',R1,R2), atom_string(R,R2).
get_en(A,R) :- xpath(A,//(p(@class=qotCE,text)),R1),chop(R1,R2),re_replace('例文帳に追加','',R2,R).
get_ja(A,R) :- xpath(A,//(p(@class=qotCJ,text)),R1),chop(R1,R2),re_replace(' - .*','',R2,R3),chop(R3,R).

get(NAME) :-
  re_replace(" "/g,"+",NAME,NAME2),
  format(atom(URL),'https://ejje.weblio.jp/sentence/content/~w',[NAME2]),
  setup_call_cleanup(http_open(URL,FP,[]),load_html(FP,HTML,[]),close(FP)),
  findall(DOC,xpath(HTML,//(div(@class=qotC)),DOC),L2),
  maplist([A,R1]>>(get_en(A,EN),get_ja(A,EJ),format(atom(R1),'    ~w ~w',[EN,EJ])),L2,L3),
  sort(L3,L4), maplist(writeln,L4).

getA(NAME) :- format('## ~w\n',[NAME]), get(NAME).
getB((NAME,J)) :- format('## ~w\n  ~w\n',[NAME,J]), get(NAME).


read_all(Filename,Atom) :- setup_call_cleanup(open(Filename, read, Str),read_file(Str,Lines),close(Str)),
                           atom_codes(Atom,Lines).
read_stream_all(Str,Atom) :- read_file(Str,Lines), atom_codes(Atom,Lines).
read_file(Stream,[])    :- at_end_of_stream(Stream).
read_file(Stream,[X|L]) :- get0(Stream,X), read_file(Stream,L).

getAll(Filename) :-
    read_all(Filename,Txt), split_string(Txt,"\n","\r\n",Lines),!,
    maplist(get,Lines).

getAll2(Filename) :-
    read_all(Filename,Txt), split_string(Txt,"\n","\r\n",Lines),!,
    maplist([A,(B,C)]>>(re_replace('[a-zA-Z_ ]+'/a,'',A,C),atom_concat(B,C,A)),Lines,Lines2),
    maplist(getB,Lines2).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% post
post(TEXT,L4) :-
  URL="https://translate.weblio.jp/",
  random_between(6101,19110,TM),
  chop(TEXT,TEXT2),
  setup_call_cleanup(http_open(URL,FP,[
    % header('Referer','https://translate.weblio.jp/'),
    method(post),
    post(form([
        lp='EJ',
        lpf='',
        rt='',
        translatedText='',
        tm=TM,
        tlt='english',
        prtRt='',
        originalText=TEXT2,
        sentenceStyle='spoken',
        spellCheckKey='53a9976f56160faf',
        
        languagePairFin='EJ',
        audioTextAreaId='originalTextArea',
        maxLimit='500',
        audioDownloadUrl='https://translate.weblio.jp/tts?query=',
        languagePairFin='EJ',
        audioTextAreaId='originalTextArea',
        maxLimit='500',
        audioDownloadUrl='https://translate.weblio.jp/tts?query='
        /*
        translatedTextWrLn0='',
        translatedTextWrLn1=''  */
      ]))
    ]),load_html(FP,HTML,[])/*read_stream_all(FP,HTML)*/,close(FP)),!,
  findall(DOC,xpath(HTML,//(table(@class=mltIchgT))/tr,DOC),L2),
  maplist([A,R1]>>(get_en1(A,EN),get_ja1(A,EJ),R1=(EN,EJ);R1=[]),L2,L3),
  exclude([[]]>>!,L3,L3_),
  sort(L3_,L4).

post25(TEXT,L5) :-
  split_string(TEXT,"\n","\r\n",Lines),
  splitN(25,Lines,Ls),!,
  maplist(post,Ls,L4s),!,
  flatten(L4s,L4),
  sort(L4,L5).
  
% 25行ずつまとめる。
splitN(_,[],[]).
splitN(N,L,[A_|Ls]) :- take(N,L,A,B), atomic_list_concat(A,' ',A_), splitN(N,B,Ls).
splitN(_,L,[Ls]) :- atomic_list_concat(L,' ',Ls).

take(0,L,[],L).
take(N,[A|L],[A|L_],R) :- N2 is N - 1, take(N2,L,L_,R).

get_en1(A,R) :- xpath(A,//(td(@class=tngMainTTG,text)),R1),chop(R1,R).
get_ja1(A,R) :- xpath(A,//(td(index(4),text)),R1),chop(R1,R).

getAll3(Filename) :-
    read_all(Filename,Txt), 
    split_string(Txt,"\n","\r\n",Lines),!,
    maplist([S,A]>>atom_string(A,S),Lines,Lines1),
    %writeln(Txt),
    post25(Txt,Dict),
    %writeln(Dict),writeln(Lines),
    maplist([A,(B,C)]>>(member((A,C),Dict),B=A;re_replace('[a-zA-Z_ ]+'/a,'',A,B),atom_concat(B,C,A),B\='';A=B,C=''),Lines1,Lines2),
    maplist([(D,E)]>>format('## 0 ~w\n  ~w\n',[D,E]),Lines2),
    maplist([(D,E)]>>format('## 0 ~w\n  ~w\n',[E,D]),Lines2),
    %halt,
    maplist(getB,Lines2).

%:- current_prolog_flag(argv, [A]),getAll(A).
%:- current_prolog_flag(argv, [A]),getAll2(A).
:- current_prolog_flag(argv, [A]),getAll3(A).

:- halt.

