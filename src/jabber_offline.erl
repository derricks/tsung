%%%  This code was developped by IDEALX (http://IDEALX.org/) and
%%%  contributors (their names can be found in the CONTRIBUTORS file).
%%%  Copyright (C) 2000-2001 IDEALX
%%%
%%%  This program is free software; you can redistribute it and/or modify
%%%  it under the terms of the GNU General Public License as published by
%%%  the Free Software Foundation; either version 2 of the License, or
%%%  (at your option) any later version.
%%%
%%%  This program is distributed in the hope that it will be useful,
%%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%%  GNU General Public License for more details.
%%%
%%%  You should have received a copy of the GNU General Public License
%%%  along with this program; if not, write to the Free Software
%%%  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
%%% 

-module(jabber_offline).
-vc('$Id$ ').
-author('nicolas.niclausse@IDEALX.com').

-include("../include/ts_profile.hrl").
-include("../include/ts_jabber.hrl").

-export([get_client/2, get_random_message/1]).


get_random_message(Args) ->
    jabber_common:get_random_message(Args).

%% generate a client session for jabber which only send messages to offline users
%% currently, parameters are included from profile.hrl
get_client(N, Id) ->
    List_Fin = [#message{ack = no_ack, thinktime=3000, param = #jabber {type = 'connect'}}, 
		#message{ack = ?messages_ack, thinktime=infinity, param = #jabber {type = 'authenticate', id = Id}},
		#message{ack = no_ack, thinktime=random:uniform(?presence_delay), param = #jabber {type = 'presence'}}] ++
	profile_jabber:get_offline_params(?messages_intensity,
					  N,
					  ?messages_size,'chat', Id) ++
	[ #message{ack = no_ack, thinktime = 100, param = #jabber {type = 'close'}}],
    List_Fin.

%%%
get_offline_params(Intensity, 1, Size, Type, Id, L) -> 
    Dest = ts_user_server:get_offline() ,
    L ++ [#message{ ack = no_ack, 
		    thinktime = ?messages_last_time,
		    param = #jabber {size=Size, 
				     type=Type,
				     id =Id,
				     dest = Dest}}];

get_offline_params(Intensity, N, Size, Type, Id, L)  ->
    Dest = ts_user_server:get_offline(),
    get_offline_params(Intensity, N-1, Size, Type, Id,
		      [#message{ ack = no_ack, 
				 thinktime = round(ts_stats:exponential(Intensity)),
				 param = #jabber {size=Size, 
						  type=Type, 
						  id = Id,
						  dest = Dest}
				}
		       | L]).
get_offline_params(Intensity, N, Size, Type, Id) when integer(N), N >= 0 ->
    get_offline_params(Intensity, N, Size, Type, Id ,[]).
