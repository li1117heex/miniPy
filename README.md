# miniPy
simple interpreter for minipy(subset of python)

### 10/22 吴健宗
上传了初步填充的代码(完善四则运算部分各符号属性的设计）
- 问题：按照四则运算的文法来看，.y代码中factor应该还有一个factor -> (add_expr)的产生式，不知道老师的代码里为什么没有。

### 10/28 吴健宗
yacc代码中完成了文法符号属性的设计
- 已实现四则运算功能（可以跑）
- 实现存储变量功能

### 10/30 吴健宗
上传了`property.h`文法符号属性设计，用来提交第一阶段报告

### 11/03 李维晟

- 修改list的底层设计，改为使用vector<type_struct*>
- `property.h`中增加打印printobj函数，用于递归打印list
- `property.h`中增加打印shallowcopy函数，用于浅拷贝。不可变对象建立了新存贮空间，而list则沿用同一个vector。
- 做出如下约定：
  - 在`assignExpr : atom_expr '=' assignExpr`的时候，存储原来的内存空间，上交浅拷贝的内存空间。赋值时候不可变对象内存已经在`factor : atom_expr`的时候更改过，所有没有影响；而list的赋值也实现了浅拷贝的要求。
  - 在`factor : atom_expr`的时候，如果检测到atom_expr时ID，就把值浅拷贝出来。这样不可变对象有了新内存空间，list的内存空间不变。
  - 在列表里包含一个变量的时候，变量的值已经被取出。所以在`List_items : add_expr | List_items ',' add_expr` 的时候，不可能有ID类型，更不可能出现list里含有ID类型的情况。
  - 其余所有不可变对象规约，比如计算，都可以利用原来的内存空间进行。而列表的运算则建立了新的列表，不能对原vector更改。
  - 总之，在对变量指向的不可变对象使用的时候，不可以改变不可变对象的值。通过新建内存空间与浅拷贝，牢牢把握`assignExpr : atom_expr '=' assignExpr`和`factor : atom_expr`两个关口，实现了这一点。

- 实现了字符串打印
- 原来打印位置错误，挪了上去
- 实现列表取元素区间

- 实现列表取元素，并通过推迟取元素完成类似`a[0]=1`赋值的正确。
  - 增加type=4，并将其范围控制在`atom_expr`内，不干扰其他，此时其指向`list_index`结构体
  - 取元素被推迟到`atom_expr`进行下一次规约时进行。
  - 在`assignExpr : atom_expr '=' assignExpr`的时候，完成要求赋值。
  - 在`factor : atom_expr`时，完成最后一次取值。

- 实现了字符串取元素形成新字符串。
- 列表创建
- 列表四则运算
- 列表的append,extend方法，类型检查也实现了
- len函数，对于字符串与列表

还没有实现的：
- 字符串取元素区间
- 其他四则运算
- print函数与相关文法

远景展望：
- 布尔类型
- list comprehension
- 上下方向键？

### 12/2 吴健宗
#### 更新
- 属性定义移动到`property.h`中，由`minipy-lab.y`调用
- 进一步明确设计: `factor -> atom_expr`这个语句中把所有在`atom_expr`中出现的ID类型变量全部extract出来(与李维晟的设计保持一致)
- 把每个文法翻译的`$$ = $1`一句放到最后,以防发生错误时提前将$$赋值
- 数值运算修改:整型和浮点型可以互相运算, 结果全部转化为浮点型
- 代码编译通过,经过debug,已经能够正常运行,目前测试通过的功能有:
    - 数值型的四则运算(整型和浮点型可以混合运算,只要出现浮点型,结果就转化为浮点型)
    - 列表的定义,取元素,取元素区间(列表嵌套也实现了)
    - 修改列表元素的值
- 上传了`overview.png`, 是整个生成式的思维导图, 便于掌握思路

#### TODO
- 实现列表方法append(), 内置函数print(), len()等
    - 创建内置函数表map<char*, 函数指针> fun_map(在main中进行函数表初始化), 保存已实现的内置函数, 根据输入的字符串调用
    - 类似的, 创建列表方法表map<char*, 函数指针> list_fun_map
    - 函数参数arglist, 定义为list_type, 一个一个读取其元素(每一个参数)即可
    - type_struct.type 中加一个void类型, 例如规定为5
