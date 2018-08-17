defmodule BLISP do
    def tokenize(code) do
        Enum.filter(String.split(String.replace(String.replace(code, "(", " ( "), ")", " ) "), " "), fn(x) -> x != "" end)
    end

    def leaf(token) do
        case Integer.parse(token) do
            {int, _} -> int
            :error -> token
            _ -> raise "Unreachable"
        end
    end

    def build_ast(tokens) do
        [token | rest] = tokens
        case token do
            "(" ->
                head_is_not_end_of_expr = fn({_, [hd | _]}) -> hd != ")" end
                {parsed, leftover} = while({[], rest}, head_is_not_end_of_expr, fn({ret, leftover}) ->
                    {parsed, leftover} = build_ast(leftover)
                    {ret ++ [parsed], leftover}
                end)
                if length(leftover) > 0 do
                    {parsed, tl(leftover)}
                else
                    {parsed, []}
                end
            ")" ->
                raise "Parse error"
            _ ->
                {leaf(token), rest}
        end
    end

    def parse(code) do
        elem build_ast(tokenize(code)), 0
    end

    def while(initial, cond, f) do
        if not cond.(initial) do
            initial
        else
            while(f.(initial), cond, f)
        end
    end

    def eval(ast, env) do
        cond do
            is_number(ast) -> ast
            ast == "true" -> true
            ast == "false" -> false
            is_binary(ast) -> env[ast]
            is_list(ast) ->
                case hd(ast) do
                    "lmb" ->
                        [_, arg, body] = ast
                        fn(x) -> eval(body, Map.put(env, arg, x)) end
                    _ ->
                        [lambda, args] = ast
                        eval(lambda, env).(eval(args, env))
                end
            true -> raise "Wrong token type: #{ast}"
        end
    end
end

IO.inspect BLISP.eval(BLISP.parse("((lmb x x) 3)"), %{})
