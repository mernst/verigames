package com.cgs.file;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

public class BaseFile {

	File m_inFile;
	File m_outFile;
	String m_outFileName;
	File m_zippedFile;
	StringBuffer outFileStringBuffer;
	
	
	public BaseFile(File inFile, File outFile)
	{
		m_inFile = inFile;
		m_outFile = outFile;
		
		m_outFileName = outFile.getName();
		int index = m_outFileName.lastIndexOf('.');
		String newFileName = m_outFileName.substring(0, index) + ".zip";
		m_zippedFile = new File(m_outFile.getParentFile(), newFileName);
		
		outFileStringBuffer = new StringBuffer();
	}
	
	//write both a uncompressed and a zipped version
	public void writeFile(boolean zipFile)
	{
		  try{
			// Create file 
			FileWriter fstream = new FileWriter(m_outFile);
			BufferedWriter out = new BufferedWriter(fstream);
			
			out.write(new String(outFileStringBuffer));
			//Close the output stream
			out.close();
		 
			if(zipFile)
			{
	    		FileOutputStream fos = new FileOutputStream(m_zippedFile);
	    		ZipOutputStream zos = new ZipOutputStream(fos);
	    		ZipEntry ze= new ZipEntry(m_outFileName);
	    		zos.putNextEntry(ze);
	    		zos.write(new String(outFileStringBuffer).getBytes());
	
	    		zos.closeEntry();
	    		zos.close();
			}

		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }
	}
	
	public void zipFileFromDisk()
	{
	   	byte[] buffer = new byte[1024];
	    
		  try{
			// Create file 
			FileOutputStream fos = new FileOutputStream(m_zippedFile);
    		ZipOutputStream zos = new ZipOutputStream(fos);
    		ZipEntry ze= new ZipEntry(m_zippedFile.getName());
    		zos.putNextEntry(ze);
    		FileInputStream in = new FileInputStream(m_inFile);
    		 
    		int len;
    		while ((len = in.read(buffer)) > 0) {
    			zos.write(buffer, 0, len);
    		}
 
    		in.close();

    		zos.closeEntry();
    		zos.close();

		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }
	}
}
