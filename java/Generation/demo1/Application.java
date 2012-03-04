class Application {
    void main() {
        Scribble sc = new Scribble();
        sc.init();

        Server s = new Server(99);
        s.run();

        Storage store = new Storage();
        store.set(new UserData("Demo Name", 44));
    }
}