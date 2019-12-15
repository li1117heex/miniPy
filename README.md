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
    
### 12/5 周泽乔
#### 更新
 - 我加入了函数的规约，但是在建立函数表的时候遇到了问题，因为void* 指针似乎不能直接访问对象
 - 此外，我向type中加入了error标识和type 5（void类型），可以解决yyerror（）后继续规约导致修改原有数据的问题，但是在其他正常情况下会是程序出现bug。

### 12/8 吴健宗
#### 问题
- 李维晟之前定义的`void type(type_struct* obj)`函数不知道是什么功能, 现在还需要不需要了
- 李维晟之前定义的另一个函数`void extend(type_struct* list1,type_struct* list2)`貌似是用来合并两个链表, 是否可以直接在`add_expr : add_expr '+' mul_expr`的产生式中调用, 以优化代码

#### 更新
- 通过error_flag标志变量实现错误处理, 一旦出错, error_flag置1, 不输出, 不赋值, 等一句规约完成后, 再将error_flag置回0)
- 与上一条类似, 使用output标志变量, 对输出进行屏蔽, 保证print()函数执行过后最后的`stat -> assignExpr`表达式不会再输出一次
- 实现函数的调用, 包括: func_map的查找, 函数指针的调用等, 可以正常使用已实现的函数
- 列表方法`atom_expr  '.' atom '(' arglist opt_comma ')'`传参时, 将列表自己的type_struct也加入args里面(用insert前插, 放在list_vec的第一个位置)
- 已实现函数: print(), list.append(), len(), quit().

#### TODO
- 继续实现其余内置函数, 函数具体功能尽量与python保持一致
    - range()
    - list()
- 列表切片赋值, 可以考虑李维晟之前说过的建立新数据结构`list_slice`, 里面存放list_vec, indexes(切片所计算出的index集合)
- 内存释放. 代码到目前为止没有考虑过内存释放的问题, 等所有功能实现完毕之后可以加入内存释放功能
    1. 在规约式里free(delete)无用的内存空间
    2. 在quit()函数中释放变量表空间(变量表本身会在程序结束时自动释放, 但是不可约变量如num_struct等是手动malloc得来, 需要人工释放)

### 12/11 周泽乔
- 上传了range（）和list（）函数，返回值均为列表。

### 12/12 李维晟
- 我们的报错是不是风格混乱。。
- a[0].append() 已经修正
- type()函数本来是判断变量类型的，本来想着可以方便debug。。

### 12/13 李维晟
- 列表取区间小bug修改
- 列表取区间赋值已经实现
- 字符串取区间已经实现
- 字符串+*实现

### 12/15
- 一些报错