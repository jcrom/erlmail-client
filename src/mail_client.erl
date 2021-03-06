%% Copyright (c) 2009-2010 Beijing RYTong Information Technologies, Ltd.
%% All rights reserved.
%%
%% No part of this source code may be copied, used, or modified
%% without the express written consent of RYTong.
-module(mail_client).

%%
%% Include files
%%

-include("client.hrl").
-include("mimemail.hrl").

%%
%% Exported Functions
%%
-export([open_retrieve_session/5,
         close_retrieve_session/1,
         list/1,
         retrieve/2,
         retrieve/3,
         open_send_session/5,
         close_send_session/1,
         send/7
        ]).


%%
%% API Functions
%%


%% Retrieve APIs

%% Options = [ssl | {timeout, integer()}]

open_retrieve_session(Server, Port, User, Passwd, Options) ->
    {ok, Fsm} = popc:connect(Server, Port, Options),
    ok = popc:login(Fsm, User, Passwd),
    {ok, Fsm}.

close_retrieve_session(Fsm) ->
    case erlang:is_process_alive(Fsm) of
        true ->
            popc:quit(Fsm);
        _ ->
            ok
    end.


list(Fsm) ->
    case popc:list(Fsm) of
        {ok, RawList} ->
            Num = get_total_number(RawList),
            ?D(Num),
            lists:map(fun(I) ->
                              {ok, C} = popc:retrieve(Fsm, I),
                              ?D({id, I}),
                              {I, retrieve_util:raw_message_to_mail(C)}
                      end, lists:seq(1, Num));
        Err ->
            ?D(Err),
            Err
    end.

retrieve(Fsm, MessageId) ->
    retrieve(Fsm, MessageId, plain).

retrieve(Fsm, MessageId, Type) ->
    case popc:retrieve(Fsm, MessageId) of
        {ok, RawMessage} ->
            retrieve_util:raw_message_to_mail(RawMessage, Type);
        Err ->
            ?D(Err),
            Err
    end.



%% Send APIs


open_send_session(Server, Port, User, Passwd, Options) ->    
    {ok, Fsm} = smtpc:connect(Server, Port, Options),
    smtpc:ehlo(Fsm, "localhost"),
    ok = smtpc:auth(Fsm, User, Passwd),
    {ok, Fsm}.

close_send_session(Fsm) ->
    case erlang:is_process_alive(Fsm) of
        true ->
            smtpc:quit(Fsm),
            ok;
        _ ->
            ok
    end.

send(Fsm, From, To, Cc, Subject, Body, Attatchments) ->
    ?D(From),
    smtpc:mail(Fsm, From),
    [smtpc:rcpt(Fsm, Address)|| Address<-To],
    [smtpc:rcpt(Fsm, Address)|| Address<-Cc],
    Mail = send_util:encode_mail(From, To, Cc, Subject, Body, Attatchments),
    ?D(Mail),
    smtpc:data(Fsm, binary_to_list(Mail)),
    ok.




%%
%% Local Functions
%%

get_total_number(Raw) ->
    Index = string:str(Raw, ?CRLF),
    [Num|_] = string:tokens(string:substr(Raw, 1, Index -1), " "),
    list_to_integer(Num).





    
           


