defmodule Util do
    def while(initial, cond, body) do
        if not cond.(initial) do
            initial
        else
            while(body.(initial), cond, body)
        end
    end
end

defmodule BLISP do
    def tokenize(code) do
        code
        |> String.replace("(", " ( ")
        |> String.replace(")", " ) ")
        |> String.replace("\n", " ")
        |> String.split()
        |> Enum.filter(fn(x) -> x != "" end)
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
                {parsed, leftover} = Util.while({[], rest}, head_is_not_end_of_expr, fn({ret, leftover}) ->
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

    @binops %{
        "+" => &+/2,
        "-" => &-/2,
        "*" => &*/2,
        "==" => &==/2
    }

    def get_result(definition, env, x) do
        eval(definition, Map.put(env, x, fn -> get_result(definition, env, x) end))
    end

    def eval(ast, env) do
        cond do
            is_number(ast) -> ast
            ast == "true" -> true
            ast == "false" -> false
            is_binary(ast) -> env[ast].() # could be memoized
            is_list(ast) ->
                cond do
                    Map.has_key?(@binops, hd(ast)) ->
                        [_, x, y] = ast
                        @binops[hd(ast)].(eval(x, env), eval(y, env))
                    hd(ast) == "if" ->
                        [_, cond, if_true, if_false] = ast
                        if eval(cond, env) do eval(if_true, env) else eval(if_false, env) end
                    hd(ast) == "let" ->
                        [_, x, definition, expression] = ast
                        eval(expression, Map.put(env, x, fn -> get_result(definition, env, x) end))
                    hd(ast) == "lmb" ->
                        [_, arg, body] = ast
                        fn(x) -> eval(body, Map.put(env, arg, fn -> x end)) end
                    true ->
                        [lambda, args] = ast
                        eval(lambda, env).(eval(args, env))
                end
            true -> raise "Wrong token type: #{ast}"
        end
    end
end

IO.inspect BLISP.eval(BLISP.parse("(let x (+ 3 4) ((lmb y (* y x)) 10))"), %{})
IO.inspect BLISP.eval(BLISP.parse("(let factorial (lmb x    (if (== x 1) 1        (* x (factorial (- x 1)))
))(factorial 10))"), %{})

