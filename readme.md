### Example usage

```nim
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
          divs:
            for i in 0..1:
              for j in 0..1:
                p $i & $j
```