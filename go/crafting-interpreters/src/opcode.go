package rekursion

type OpCode byte

const (
	OpReturn OpCode = iota
	OpConst
	OpNil
	OpTrue
	OpFalse
	OpPop
	OpGetLocal
	OpSetLocal
	OpGetGlobal
	OpDefGlobal
	OpSetGlobal
	OpGetUpval
	OpSetUpval
	OpGetProp
	OpSetProp
	OpGetSuper
	OpEqual
	OpGreater
	OpLess
	OpNot
	OpNeg
	OpAdd
	OpSub
	OpMul
	OpDiv
	OpPrint
	OpJump
	OpJumpUnless
	OpLoop
	OpCall
	OpInvoke
	OpSuperInvoke
	OpClos
	OpCloseUpval
	OpClass
	OpInherit
	OpMethod
)
