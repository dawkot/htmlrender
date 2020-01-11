import macros, tables, sequtils, strformat, sets


# Utils

template isVoid(x): bool =
  not compiles (let _ = x)


# Tags

const tags = toHashSet [
  # Basic
  "html", "head", "title", "body",
  "h1", "h2", "h3", "h4", "h5", "h6",
  "p", "br", "hr",
  # Formatting
  "acronym", "abbr", "address", "b", "bdi", "bdo",
  "blockquote", "cite", "code", "del", "dfn", "em",
  "i", "ins", "kbd", "mark", "meter", "pre", "progress",
  "q", "rp", "rt", "ruby", "s", "samp", "small", "strong",
  "sub", "sup", "template", "time", "u", "var", "wbr",
  # Forms and Input
  "form", "input", "textarea", "button", "select",
  "optgroup", "option", "label", "fieldset", "legend",
  "datalist", "output",
  # Frames
  "iframe",
  # Images
  "img", "map", "area", "canvas", "figcaption", "figure",
  "picture", "svg",
  # Audio
  "audio", "source", "track", "video",
  # Links
  "a", "link", "nav",
  # Lists
  "ul", "ol", "li", "dl", "dt", "dd",
  # Tables
  "table", "caption", "th", "tr", "td",
  "thead", "tbody", "tfoot", "col", "colgroup",
  # Styles and Semantics
  "style", "div", "span", "header", "footer",
  "main", "section", "article", "aside", "details",
  "dialog", "summary", "data",
  # Meta Info
  "head", "meta", "base",
  # Programming
  "script", "noscript", "embed", "object", "param"]

const dontClose = toHashSet ["meta", "link"]

const maps = toTable { "divs": "div" }

proc parseTag(n: NimNode): string =
  if n.kind == nnkIdent:
    let s = maps.getOrDefault($n, $n)
    if s in tags:
      return s


# Main

var v {.compiletime.}: NimNode

proc add(n: NimNode): NimNode =
  quote: `v`.add `n`

proc attr(n: NimNode): NimNode =
  expectKind n, nnkExprEqExpr
  let (key, val) = ($n[0], n[1])
  add newLit &"{key}=\"{val}\""

proc node(tag: string, attrs: openarray[NimNode] = [], body: NimNode = nil): NimNode =
  result = newStmtList()
  if tag == "html":
    result.add add newLit "<!doctype html>"
  result.add add newLit &"<{tag}"
  for it in attrs:
    result.add add newLit ' '
    result.add attr it
  result.add add newLit '>'
  if body != nil:
    result.add body
  if tag notin dontClose:
    result.add add newLit &"</{tag}>"


proc impl(n: NimNode): NimNode =
  
  if n.kind == nnkIdent and (let tag = parseTag n; tag != ""):
    return node tag
  
  elif n.kind in CallNodes and (let tag = parseTag n[0]; tag != ""):
    if n.len == 1: # just the name
      return node tag
    else:
      result = newStmtList()
      var attrs = n[1..^2]
      var body: NimNode      
      if last(n).kind == nnkExprEqExpr:
        attrs.add last n
      else:
        body = impl last n
      return node(tag, attrs, body)      
    
  elif n.kind == nnkStmtList:
    return newStmtList n.mapIt(impl it)
  
  elif n.kind == nnkForStmt:
    n[2] = impl n[2]
    return n
  
  elif n.kind == nnkIfStmt:
    for it in n:
      let i = if it.kind == nnkElifBranch: 1 else: 0
      it[i] = impl it[i]
    return n
  
  elif n.kind == nnkDiscardStmt:
    return n

  else:
    return quote:
      when isVoid `n`:
        `n`
      elif `n` is string or `n` is char:
        `v`.add `n`


# Export

macro html*(nodes): string =
  result = newStmtList()
  v = genSym nskVar
  result.add quote do: (var `v` = "")
  result.add impl nodes
  result.add v

macro html*(first, rest): string =
  getAst html nnkCall.newTree(first, rest)


# Test

when isMainModule:  
  import strutils

  template `?=`(a, b) =
    if a != b:
      echo "False assumption: ", astToStr(a) & " == " & astToStr(b)
      echo astToStr(a) & " :: " & a
      echo astToStr(b) & " :: " & b
      quit QuitFailure

  block:
    let a = html divs:
      p "Foo"
    let b = html:
      divs:
        p "Foo"
    a ?= b

  block:
    let a = html:
      html(lang="en"):
        head:
          meta(charset="utf-8")
          title "myTitle"
          meta(name="description", content="myDescription")
          meta(name="author", content="myName")
          link(rel="stylesheet", href="myCss")
        body:
          script(src="myScript")
          if true: "t" else: "f"
          if false: "f"
          if true: "t"
          discard "foo"
          divs:
            for i in 0..1:
              for j in 0..1:
                p $i & $j
      
    let b = """
      <!doctype html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>myTitle</title>
        <meta name="description" content="myDescription">
        <meta name="author" content="myName">
        <link rel="stylesheet" href="myCss">
      </head>
      <body>
        <script src="myScript"></script>
        t
        t
        <div>
          <p>00</p>
          <p>01</p>
          <p>10</p>
          <p>11</p>
        </div>
      </body>
      </html>""".unindent.replace("\n", "")

    a ?= b