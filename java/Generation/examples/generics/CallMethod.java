interface List<T extends Object> {}

class ListImp implements List<String> {}

class CallMethod {
	public <T extends List<String>> String call(T t) {
		return "any";
	}
	
	public static void main() {
		List<String> s = null;
		CallMethod cm = new CallMethod();
		
		cm.call(new ListImp());
		String retStore = cm.call(null);
		
		cm.<ListImp>call(null);
		cm.<List<String>>call(null);
	}
}