% 英語例文 スクレイピング on prolog

% 英語の例文を調べるのが面倒なので、スクレイピングして結果を返すものを作ってみたいと思います。
% Prologでスクレイピングをしてみていたので、Prologでやってみます。

% とりあえずソースを拾ってきてある状態から始めます。
chop(A,R) :-
  re_replace('[ \\t\\r\\n]+'/g,' ',A,R1),
  re_replace('(^ +| +$)'/g,'',R1,R2),
  atom_string(R,R2).

get_en(A,R) :- xpath(A,//(p(@class=qotCE,text)),R1),chop(R1,R2),re_replace('例文帳に追加','',R2,R).
get_ja(A,R) :- xpath(A,//(p(@class=qotCJ,text)),R1),chop(R1,R2),re_replace(' - .*','',R2,R3),chop(R3,R).

:- use_module(library(http/http_open)).

get(NAME) :-
  format(atom(URL),'https://ejje.weblio.jp/sentence/content/~w',[NAME]),
  format('load ~w\n',[URL]),
  setup_call_cleanup(
     http_open(URL,FP,[]),
     load_html(FP,HTML,[]),
     close(FP)),
  findall(DOC,xpath(HTML,//(div(@class=qotC)),DOC),L2),
  maplist([A,R1]>>(get_en(A,EN),get_ja(A,EJ),format(atom(R1),'    ~w ~w',[EN,EJ])),L2,L3),
  sort(L3,L4),
  maplist(writeln,L4).
% :- get(arrange).
:- current_prolog_flag(argv, [A]),get(A).
:- halt.
