def tokenize(code):
    return [token for token in code.replace('(', '( ').replace(')', ' )').replace('\n', '').split(' ') if token != '']

def leaf(token):
    try: return int(token)
    except: return token

def build_ast(tokens):
    if len(tokens) == 0: raise Exception("Parse Error")

    token = tokens.pop(0)
    if token == '(':
        ret = []
        while tokens[0] != ')':
            ret.append(build_ast(tokens))
        tokens.pop(0)
        return ret
    elif token == ')':
        raise Exception("Parse error 2")
    else:
        return leaf(token)


def parse(code): return build_ast(tokenize(code))


operations = {
    '+': lambda x, y: x + y,
    '-': lambda x, y: x - y,
    '*': lambda x, y: x * y,
    '==': lambda x, y: x == y
}

def eval(ast, env = {}):
    if   type(ast) == int: return ast
    elif ast == 'true': return True
    elif ast == 'false': return False
    elif type(ast) == str and ast in operations: return operations[ast]
    elif type(ast) == str: return env[ast]

    assert(type(ast) == list)
    op, *args = ast
    if op == 'let':
        [x, definition, expression] = args
        new_env = env.copy()
        new_env[x] = eval(definition, new_env)
        return eval(expression, new_env)

    elif op == 'if':
        assert(len(ast) == 4)
        [cond, if_true, if_false] = args
        return eval(if_true, env) if eval(cond, env) else eval(if_false, env)

    # Functions!
    elif op == 'lmb':
        assert(type(ast[1]) == str)
        *variables, expression = args
        def lmb(*args):
            assert(len(args) == len(variables))
            return eval(expression, {**env, **{variables[i]: args[i] for i in range(len(args))}})
        return lmb

    # Function calls! - pass by value
    else:
        return eval(ast[0], env)(*[eval(expr, env) for expr in ast[1:]])


code = '(+ 5 (* 2 4))'
code2 = "(let x {} (* 2 x))".format(code)
code3 = '((lmb x (* 2 x)) 2)'
code4 = "(let double (lmb x (* 2 x)) (double 3))"
code5 = "(let double (lmb x (* 2 x)) ((lmb a (a 3)) double))"
code6 = '(if false 3 4)'

fact = """(
    let factorial (lmb x
        (if (== x 1) 1
            (* x (factorial (- x 1)))
        )
    ) (factorial 10)
)"""

currying = """(
    let sum (lmb a
        (lmb b (+ a b))
    ) ((sum 3) 4)
)"""

multi_args = """(
    let sum (lmb a b
        (+ a b)
    ) (sum 3 4)
)"""

# Define our own polymorphic list type
# false :: List (nil)
# (bool) -> (any | List) :: List (cons)
# cons :: (any, List) -> (bool) -> (elem | List)
list_fun = """(
    let cons (lmb a b
        (lmb x (if x a b))
    ) (
    let hd (lmb lst (lst true)) (
    let tl (lmb lst2 (lst2 false))
    (hd (tl (cons 3 (cons 4 false))))
)))"""

print(eval(parse(list_fun)))
