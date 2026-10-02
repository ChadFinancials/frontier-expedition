"""Writes data/events.json in the project's hand-edited layout (one outcome per line).

Usage from another script:  from fmt_events import dump; open(p, 'w').write(dump(events))
Run directly to re-format the file in place:  python3 tools/fmt_events.py
"""
import json
import os

PATH = os.path.join(os.path.dirname(__file__), "..", "data", "events.json")
OPT_HEAD = ["text", "requires", "consume", "compel", "hide_if"]


def j(v):
    return json.dumps(v, ensure_ascii=False)


def _outcome(o, indent):
    """One line per outcome; a follow-up ("then") opens its options on the lines below."""
    if "then" not in o:
        return indent + j(o)
    head = {k: v for k, v in o.items() if k != "then"}
    t = o["then"]
    s = indent + j(head)[:-1] + ', "then": {"text": %s, "options": [\n' % j(t["text"])
    s += ",\n".join(_option(x, indent + "  ") for x in t["options"])
    return s + "]}}"


def _outcomes(outs, indent):
    return ",\n".join(_outcome(o, indent) for o in outs)


def _option(o, indent="      "):
    head = ", ".join("%s: %s" % (j(k), j(o[k])) for k in OPT_HEAD if k in o)
    rest = [k for k in o if k not in OPT_HEAD and k != "outcomes"]
    s = indent + "{" + head
    for k in rest:
        s += ",\n%s  %s: %s" % (indent, j(k), j(o[k]))
    s += ', "outcomes": [\n' if not rest else ',\n%s  "outcomes": [\n' % indent
    s += _outcomes(o["outcomes"], indent + "  ") + "]}"
    return s


def dump(events):
    parts = []
    for k, v in events.items():
        if not isinstance(v, dict):
            parts.append("  %s: %s" % (j(k), j(v)))
            continue
        head = ", ".join("%s: %s" % (j(x), j(v[x])) for x in v if x not in ("text", "options"))
        s = "  %s: {%s,\n    \"text\": %s,\n    \"options\": [\n" % (j(k), head, j(v["text"]))
        s += ",\n".join(_option(o) for o in v["options"]) + "\n    ]}"
        parts.append(s)
    return "{\n" + ",\n\n".join(parts) + "\n}\n"


if __name__ == "__main__":
    ev = json.load(open(PATH, encoding="utf-8"))
    open(PATH, "w", encoding="utf-8", newline="\n").write(dump(ev))
