.class public test1
.super java/lang/Object
.field public static _sc Ljava/util/Scanner;
.method public static main([Ljava/lang/String;)V
.limit stack 100
.limit locals 100
	new java/util/Scanner
	dup
	getstatic java/lang/System/in Ljava/io/InputStream;
	invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V
	putstatic test1/_sc Ljava/util/Scanner;
	ldc 1
	istore 1
	iload 1
	ldc 1
	isub
	ifeq L1
	iconst_0
	goto L2
L1:
	iconst_1
L2:
	ifeq Lelse_2
	getstatic java/lang/System/out Ljava/io/PrintStream;
	ldc "=="
	invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V
	goto Lexit_2
Lelse_2:
	getstatic java/lang/System/out Ljava/io/PrintStream;
	ldc "!="
	invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V
Lexit_2:
	iload 1
	ldc 1
	isub
	ifeq L4
	iconst_0
	goto L5
L4:
	iconst_1
L5:
	ifeq Lelse_5
	getstatic java/lang/System/out Ljava/io/PrintStream;
	ldc "=="
	invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V
Lelse_5:
	getstatic java/lang/System/out Ljava/io/PrintStream;
	ldc "end"
	invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V
	return
.end method
