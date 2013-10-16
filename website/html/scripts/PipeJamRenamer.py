#!/usr/bin/env python
# -*- coding: UTF-8 -*-

#renames files using the PipeJam renaming system
import sys, os

color_names = [
		"Aqua", "Azure", "Blue", "Black", "Brown", "Coral", "Cyan", "Fuchsia", "Gray", "Green", "Indigo", "Ivory", "Khaki", "Lavendar", 
		"Lime", "Magenta", "Maroon", "Mint", "Navy", "Olive", "Orange", "Pink", "Plum", "Purple", "Red", "Salmon", "Silver", "Teal",
		"Turquoise", "Violet", "White", "Yellow"
		];
		
		
nature_nouns = [
		"Desert", "Canyon", "Clay", "Dunes", "Falls", "Forest", "Hills", "Lake", "Meadows", "Mountain", "Oak", "Peak", "Plains", "Plateau", 
		"Prairie", "River", "Shores", "Shrub", "Springs", "Stream", "Rock", "Valley", "Woods"
		];
		
adjectives = [
		"Abandoned", "Bright", "Busy", "Calm", "Clear", "Cool", "Curious", "Cynical", "Dark", "Dashing", "Dazzling", "Dead", "Deep", "Defiant",
		"Dizzy", "Dry", "Dusty", "Dynamic", "Early", "Electric", "Elite", "Empty", "False", "Famous", "Feeble", "Flat", "Frantic", "Friendly",
		"Gentle", "Giant", "Gleaming", "Handsome", "Happy", "Harsh", "Heavy", "Hollow", "Hot", "Husky", "Immense", "Jagged", "Jolly", "Keen",
		"Kindly", "Large", "Little", "Long", "Loud", "Lovely", "Lucky", "Macho", "Mad", "Marvelous", "Mellow", "Misty", "Murky", "New", "Nifty",
		"Noisy", "Normal", "Odd", "Old", "Optimal", "Pale", "Perfect", "Placid", "Polite", "Precious", "Pretty", "Prickly", "Proud", "Quick",
		"Quiet", "Rainy", "Rapid", "Regular", "Rich", "Rough", "Rural", "Rustic", "Salty", "Secret", "Shaggy", "Sharp", "Shiny", "Shy", "Silent",
		"Simple", "Slim", "Slow", "Small", "Smooth", "Soft", "Sore", "Spiffy", "Stale", "Steady", "Steep", "Stormy", "Sturdy", "Super", "Sweet",
		"Swift", "Tall", "Teeny", "Tense", "Terrific", "Thirsty", "Tidy", "Tiny", "Tough", "Tricky", "Ultra", "Unique", "Useful", "Vague", "Vast",
		"Verdant", "Wacky", "Warm", "Weary", "Wide", "Witty", "Young"
		];
		
place_suffixes = [
		"boro", "City", "Corner", "Depot", "ford", "ham", "Hamlet", "Junction", "mount", "Park", "Port", "Station", "ton", "Town", "Village", "ville"
		];
		

if __name__ == "__main__":
	
	inputpath = sys.argv[1]
	outputpath = sys.argv[2]
	
	index1 = 0
	index2 = 0
	index3 = 0
	index4 = 0

	#find all constraints files
	cmd = os.popen('dir /w %s*Constraints.xml' % inputpath)
	for filename in cmd:
		#get root file name
		fileroot = filename.strip().lstrip(inputpath).rstrip('Constraints.xml')
		
		#get new file name
		filename = adjectives[index1] + nature_nouns[index2]
		index1 = index1+1
		if(index1 == len(nature_nouns)):
			index1 = 0
			index2 = index2 + 1
		
		sys.stdout.write('copy %s%s.xml %s%s.xml\n' % (inputpath, fileroot, outputpath, filename))
		#now copy all three files with new name to output directory
		os.popen('copy %s%s.xml %s%s.xml' % (inputpath, fileroot, outputpath, filename))
		os.popen('copy %s%sLayout.xml %s%sLayout.xml' % (inputpath, fileroot, outputpath, filename))
		os.popen('copy %s%sConstraints.xml %s%sConstraints.xml' % (inputpath, fileroot, outputpath, filename))
	
	