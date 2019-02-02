/
==================================
Module mapping library for embedPy
==================================
Maps a python module to a q context
Drill down dictionary:
module
|--> class1
       |---> prop1 [getter;setter;deleter]
       ----> func1 [args;default;values;required;doc]
       ----> func2 [args;default;values;required;doc]
\

\l p.q
\l lib/reflect.p

.py.imp:()!();

.py.meta.:(::);

.py.mod_info:.p.get[`module_info;<];

.py.import:{[mdl] 
  if[mdl in key .py.imp;
    -1"Module already imported"; :(::)];
  if[@[{.py.imp[x]:.p.import x;1b}; mdl; .py.error[mdl]];
    ns:` sv (`.pq; mdl);
    ns set (!/) enlist each (`;::);
    -1"Imported python module '",string[mdl],"'"];
  };

.py.reflect:{[mdl]
  imp: .py.imp[mdl];
  nfo: .py.mod_info[imp];
  cls: nfo[`classes];
  ref: .py.project[imp; cls];
  .pq[mdl],:ref;
  .py.meta[mdl]:nfo;
  1b};

.py.error:{[mdl; err]
  -1"Python module '",string[mdl],"' failed with: ", "(",err,")";
  0b};

.py.project:{[imp; cls]
  p: {key [x]y'x}[cls;{
      obj: x hsym y;
      atr: z`attributes;
      cxt: .py.cxt[obj; atr];
      cxt}[imp]];
  p};

.py.cxt:{[obj; atr; args]
  data: atr`data;
  prop: atr`properties;
  func: atr`functions;

  init: func[`$"__init__"];
  params: init[`parameters];
  required: params[::;`required];

  if[(args~(::)) and (any required);
    '"Missing required parameters: ",", " sv string where required];

  args: .py.args[args];
  apply: $[1<count args;.;@];
  inst: apply[obj;args];

  func _: `$"__init__";
  vars: .pq.builtins.vars[inst];
  docs: enlist[`]!enlist[::];

  if[count data; docs[`data]: data];
  if[count prop; docs[`prop]: prop];
  if[count func; docs[`func]: func];
  if[count vars; docs[`vars]: vars];

  mD: .py.mapData[inst; data];
  mP: .py.mapProp[inst; prop];
  mF: .py.mapFunc[inst; func];
  mV: .py.mapVars[inst; vars];
  cx: enlist[`]!enlist[::];
  cx: mD,mP,mF,mV;
  cx[`docs_]:docs;
  cx};

.py.strToSym:{ if[any {(type x) in ((5h$til 20)_10),98 99h}@\:x; :.z.s'[x]]; $[10h = abs type x; `$x; x] };
.py.isDict:{ (99h = type x) and (not .Q.qt x) };
.py.isGList:{ 0h = type x };

.py.args:{[args]
  if[args~(::);:args];
  
  args: .py.strToSym[args];

  if[.py.isDict args;
    if[10h = type key args;
      args:({`$x} each key args)!value args];
    ]; 

  args: $[.py.isDict args; pykwargs args; 
          (.py.isGList args) and (.py.isDict last args);
            (pyarglist -1 _ args; pykwargs last args); 
              pyarglist args];
  args};

.py.mapData:{[obj; d]
  k: key d;
  v: obj@'hsym k;
  m: k!v;
  m};

.py.mapProp:{[ins; d]
  m: {key [x]y'x}[d;{
      h: hsym y;
      d: (enlist `get)!(enlist x[h;]);
      if[z`setter; d[`set]:x[:;h;]];
      d}[ins]];
  m};

.py.mapFunc:{[ins; d]
  f: key d;
  m: f!ins[;<]@'hsym f;
  m};

.py.mapVars:{[ins; d]
  k: key d;
  h: hsym k;
  v:{ g: x[y;];
      s: x[:;y;];
      `get`set!(g;s)}[ins;] each h;
  m: (!/)($[1>=count k; {$[not (0h <= type x) and (20h > type x);enlist x; x]} each;](k;v));
  m};

.py.attrs:.p.get[`get_attrs;<];

.py.imap:{[p; f]
  i: .py.imp[p];
  m: f!i[;<]@'hsym f;
  .pq[p],:m; m};

.py.import[`builtins];

.py.imap[`builtins;`list`next`vars`str];
