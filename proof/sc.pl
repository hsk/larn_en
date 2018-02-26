:- use_module(library(http/http_open)).
% 英語例文 スクレイピング on prolog

% 英語の例文を調べるのが面倒なので、スクレイピングして結果を返すものを作ってみたいと思います。
% Prologでスクレイピングをしてみていたので、Prologでやってみます。

% とりあえずソースを拾ってきてある状態から始めます。
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
        originalText=TEXT,
        sentenceStyle='spoken',
        spellCheckKey='21d3c33285b0efa6',
        
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
  findall(DOC,xpath(HTML,//(table(@class=mltIchgT))/tr,DOC),[_|L2]),
  maplist([A,R1]>>(get_en1(A,EN),get_ja1(A,EJ),R1=[EN,EJ]),L2,L3),
  sort(L3,L4).

get_en1(A,R) :- xpath(A,//(td(@class=tngMainTTG,text)),R1),chop(R1,R).
get_ja1(A,R) :- xpath(A,//(td(index(4),text)),R1),chop(R1,R).
/*
:- 
  setup_call_cleanup(open("trans.html",read,FP),load_html(FP,HTML,[]),close(FP)),
  findall(DOC,xpath(HTML,//(table(@class=mltIchgT))/tr,DOC),[_|L2]),
  maplist([A,R1]>>(get_en1(A,EN),get_ja1(A,EJ),format(atom(R1),'(~w,~w)',[EN,EJ])),L2,L3),
  sort(L3,L4), maplist(writeln,L4).
:- halt.
*/

getAll3(Filename) :-
    read_all(Filename,Txt), 
    split_string(Txt,"\n","\r\n",Lines),!,
    maplist([S,A]>>atom_string(A,S),Lines,Lines1),
    %post(Txt,Dict),
    Dict=[[antisymmetric,'反対称性の, 反対称な'],[despite,'…にもかかわらず'],[obvious,'(疑問の余地がないほど)明らかな, 明白な, すぐにわかる, 理解しやすい'],[precisely,'正確に, 精密に, 的確に'],[suffices,'sufficeの三人称単数現在。満足させる, 十分である'],[tedious,'長ったらしくて退屈な, あきあきする, つまらない']],
%    writeln(Dict),writeln(Lines),
    maplist([A,(B,C)]>>(member([A,C],Dict),B=A;re_replace('[a-zA-Z_ ]+'/a,'',A,B),atom_concat(B,C,A),B\='';A=B,C=''),Lines1,Lines2),
%   maplist(writeln,Lines2).
    maplist(getB,Lines2).

%:- current_prolog_flag(argv, [A]),getAll(A).
%:- current_prolog_flag(argv, [A]),getAll2(A).
:- current_prolog_flag(argv, [A]),getAll3(A).

:- halt.

