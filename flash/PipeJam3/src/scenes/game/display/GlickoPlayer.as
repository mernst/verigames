package scenes.game.display 
{
	/**
	 * Glicko2 implementation
	 */
	public class GlickoPlayer
	{
		public static var tau:Number;
		public var rating:Number;
		public var ratingDeviation:Number;
		public var volatility:Number;
		
		public function GlickoPlayer(_rating:Number=1500, _rd:Number=350, _vol:Number=0.06) 
		{
			tau = 0.5;
			setRating(_rating);
			setRD(_rd);
			volatility = _vol;
		}
		
		public function getRating():Number
		{
			return ((rating * 173.7178) + 1500);
		}
		
		public function setRating(_rating:Number):void
		{
			rating = (_rating - 1500) / 173.7178;
		}
		
		public function getRD():Number
		{
			return (ratingDeviation * 173.7178);
		}
		
		public function setRD(_rd:Number):void
		{
			ratingDeviation = (_rd / 173.7178);
		}
		
		public function getInternalRating():Number
		{
			return rating;
		}
		
		public function getInternalRD():Number
		{
			return ratingDeviation;
		}
		
		/* Calculates and updates the player's rating deviation for the beginning of a rating period. */
		public function preRatingRD():void
		{
			/*
			trace("inside prerating:");
			trace("RD: " + ratingDeviation);
			trace("volatility: " + volatility);
			trace("RD^2: " + Math.pow(ratingDeviation, 2));
			trace("vol^2: " + Math.pow(volatility, 2));
			trace("Sqrt: " + Math.sqrt(Math.pow(ratingDeviation, 2) + Math.pow(volatility, 2)));
			*/
			ratingDeviation = Math.sqrt(Math.pow(ratingDeviation, 2) + Math.pow(volatility, 2));
		}
		
		/* Calculates the new rating and rating deviation of the player. */
		public function updatePlayer(p2Rating:Number, p2RD:Number, outcome:Number):void
		{
			//trace("Inside GlickoPlayer.updatePlayer: ");
			//trace("Initial rating: " + rating);
			p2Rating = (p2Rating - 1500) / 173.7178;
			//trace("p2Rating: " + p2Rating);
			p2RD /= 173.7178;
			//trace("p2RD: " + p2RD);
			var v:Number = V(p2Rating, p2RD);
			//trace("V: " + v);
			volatility = newVolatility(p2Rating, p2RD, outcome, v);
			//trace("Volatility: " + volatility);
			//trace("Before prerating: " + ratingDeviation);
			preRatingRD();
			//trace("After prerating: " + ratingDeviation);
			
			ratingDeviation = 1 / Math.sqrt((1 / Math.pow(ratingDeviation, 2)) + (1 / v))
			//trace("Rating dev: " + ratingDeviation);
        
			var tempSum:Number = 0;
			tempSum += g(p2RD) * (outcome - E(p2Rating, p2RD));
			//trace("tempSum: " + tempSum);
			rating += Math.pow(ratingDeviation, 2) * tempSum;
			//trace("New Rating: " + rating);
		}
		
		/* Calculating the new volatility as per the Glicko2 system. */
		public function newVolatility(currentRating:Number, currentRD:Number, outcome:Number, v:Number):Number
		{
			var i:int = 0;
			var del:Number = delta(currentRating, currentRD, outcome, v);
			var a:Number = Math.log(Math.pow(volatility, 2));
			var _tau:Number = tau;
			var x0:Number = a;
			var x1:Number = 0;
			
			while (Math.abs(x0 - x1) > 0.001)
			{
				x0 = x1;
				var d:Number = Math.pow(rating, 2) + v + Math.exp(x0);
				var h1:Number = -(x0 - a) / Math.pow(_tau, 2) - 0.5 * Math.exp(x0) / d + 0.5 * Math.exp(x0) * Math.pow(del / d, 2);
				var h2:Number = -1 / Math.pow(_tau, 2) - 0.5 * Math.exp(x0) * (Math.pow(rating, 2) + v) / Math.pow(d, 2) + 0.5 * Math.pow(del, 2) * Math.exp(x0) * (Math.pow(rating, 2) + v - Math.exp(x0)) / Math.pow(d, 3);
				x1 = x0 - (h1 / h2);
			}

			return Math.exp(x1 / 2);
		}
		
		/* The delta function of the Glicko2 system. */
		public function delta(currentRating:Number, currentRD:Number, outcome:Number, v:Number):Number
		{
			var tempSum:Number = 0;
			tempSum += g(currentRD) * (outcome - E(currentRating, currentRD));
			return v * tempSum;
		}
		
		/* The v function of the Glicko2 system. */
		public function V(currentRating:Number, currentRD:Number):Number
		{
			 //trace("Inside V... ");
			 var tempSum:Number = 0;
			 var tempE:Number = E(currentRating, currentRD);
			 //trace("tempE: " + tempE + "\t1 - tempE: " + (1 - tempE));
			 tempSum += Math.pow(g(currentRD), 2) * tempE * (1 - tempE);
			 //trace("tempSum: " + tempSum);
			 return (1 / tempSum);
		}
		
		/* The Glicko E function. */
		public function E(p2rating:Number, p2RD:Number):Number
		{
			return 1 / (1 + Math.exp( -1 * g(p2RD) * (rating - p2rating)));
		}
		
		/* The Glicko2 g function. */
		public function g(RD:Number):Number
		{
			return 1 / Math.sqrt(1 + 3 * Math.pow(RD, 2) / Math.pow(Math.PI, 2));
		}
		
		/* Applies Step 6 of the algorithm. Use this for players who did not compete in the rating period. */
		public function didNotCompete():void
		{
			preRatingRD();
		}
		
	}

}