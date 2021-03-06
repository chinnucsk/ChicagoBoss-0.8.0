-module(boss_erlydtl_tags).
-export([url/2]).

url(Variables, Options) ->
    ListVars = lists:map(fun 
            ({K, V}) when is_binary(V) -> {K, binary_to_list(V)}; 
            ({K, V}) -> {K, V} 
        end, Variables),
    ThisApp = proplists:get_value(application, Options),
    LinkedApp = proplists:get_value(application, ListVars, ThisApp),
    ThisController = proplists:get_value(controller, Options),
    LinkedController = proplists:get_value(controller, ListVars, ThisController),
    DefaultAction = case proplists:get_value(controller, ListVars) of
        undefined ->
            proplists:get_value(action, Options);
        _ ->
            undefined
    end,
    Action = proplists:get_value(action, ListVars, DefaultAction),

    CleanVars = lists:foldl(fun(Key, Vars) ->
                proplists:delete(Key, Vars)
        end, ListVars, [application, controller, action]),

    NoUndefinedVars = lists:foldl(fun
            ({_, undefined}, Acc) ->
                Acc;
            (KV, Acc) ->
                [KV|Acc]
        end, [], CleanVars),

    ProtocolPlusDomain = case ThisApp =:= LinkedApp of
        true -> "";
        false ->
            case boss_web:domains(list_to_atom(lists:concat([LinkedApp]))) of
                all -> "";
                Domains -> 
                    UseSameDomain = case proplists:get_value(host, Options) of
                        undefined -> false;
                        DefinedHost -> 
                            [H|_] = re:split(DefinedHost, ":", [{return, list}]),
                            lists:member(H, Domains)
                    end,
                    case UseSameDomain of
                        true -> "";
                        false -> "http://" ++ hd(Domains)
                    end
            end
    end,

    RouterPid = proplists:get_value(router_pid, Options),
    URL = boss_router:unroute(RouterPid, LinkedController, Action, NoUndefinedVars),
    BaseURL = boss_web:base_url(list_to_atom(lists:concat([LinkedApp]))),
    ProtocolPlusDomain ++ BaseURL ++ URL.
