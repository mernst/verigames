interface List<@1 T extends @0 Object> {}

class ListImp extends @2 Object implements @3 List<@4 String> {
	/** @5 init(#6 this) */
}

class CallMethod extends @7 Object {
	/** @8 init(@9 this) */
	
	public <@12 T extends @10 List<@11 String>> @13 String call(/** @14 this */ @15 T t) {
		return "any";	
	}
	
	public static void main() {
		@16 CallMethod cm = new @17 CallMethod();
		
		@19 String retStore = cm.call(new @18 ListImp());
		cm.call(null);
	}
}

1 <: Constant(@nninf.quals.Nullable)
1 <: 0
1 <: Constant(@nninf.quals.NonNull)
4 <: 0
1 <: 4
6 <: 2
5 <: 2
9 <: 7
8 <: 7
14 <: 7
13 <: 11
12 <: Constant(@nninf.quals.Nullable)
12 <: 10
Literal(STRING_LITERAL, "any") <: 13
Constant(@nninf.quals.Nullable) <: 7
17 <: 16
17 <: 8
17 != Constant(@nninf.quals.Nullable)
15 <: Constant(@nninf.quals.Nullable)
18 <: 15
18 <: Constant(@nninf.quals.Nullable)
18 <: 5
18 != Constant(@nninf.quals.Nullable)
16 != Constant(@nninf.quals.Nullable)
CallInstanceMethodConstraint(     
    caller: method CallMethod#main():V constraint position; 
    receiver: @VarAnnot(14) CallMethod; 
    called method: method CallMethod#call(LList;):Ljava/lang/String;; <>(@VarAnnot(18) ListImp)
    result: @VarAnnot(13) String;  )
19 <: 4
13 <: 19
Literal(NULL_LITERAL, "null") <: 15
CallInstanceMethodConstraint(     
    caller: method CallMethod#main():V constraint position; 
    receiver: @VarAnnot(14) CallMethod; 
    called method: method CallMethod#call(LList;):Ljava/lang/String;; <>(null)
    result: @VarAnnot(13) String;  )
    
Literal(NULL_LITERAL, "null") <: Constant(@nninf.quals.Nullable)'

Missing 
@4 == @11
@10 <: @0
@1 <: @10
@1 <: @12


