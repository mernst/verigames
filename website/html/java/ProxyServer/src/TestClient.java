import java.io.*;
import java.net.*;
import java.util.Timer;
import java.util.TimerTask;

public class TestClient {
	public static void main(String[] args) throws IOException {
		 
		Timer timer = new Timer();
		
		timer.scheduleAtFixedRate(new TimerTask() {
			  @Override
			  public void run()  
			  {
				  try{
					  sendMessage();
				  }
				  catch(Exception e) {}
			  }
			}, 5*1000, 5*1000);
	}
	
	static void sendMessage() throws IOException
	{
        Socket kkSocket = null;
        PrintWriter out = null;
        BufferedReader in = null;
 
        try {
            kkSocket = new Socket("localhost", 4444);
            System.out.println("Connecting");
            out = new PrintWriter(kkSocket.getOutputStream(), true);
            System.out.println("Sending");
            in = new BufferedReader(new InputStreamReader(kkSocket.getInputStream()));
        } catch (UnknownHostException e) {
            System.err.println("Don't know about host: localhost.");
            System.exit(1);
        } catch (IOException e) {
            System.err.println("Couldn't get I/O for the connection to: localhost.");
            System.exit(1);
        }
 
     //   BufferedReader stdIn = new BufferedReader(new InputStreamReader(System.in));
        String fromServer;
//        String fromUser;
 
        if ((fromServer = in.readLine()) != null) {
            System.out.println("Server: " + fromServer);
//            if (fromServer.equals("quit"))
//                break;
             
//            fromUser = stdIn.readLine();
//        if (fromUser != null) {
//                System.out.println("Client: " + fromUser);
//                out.println(fromUser);
//        }
        }
 
        out.close();
        in.close();
 //       stdIn.close();
        kkSocket.close();
    }
}
