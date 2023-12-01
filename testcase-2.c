ECHO main()
{
	LENGTHY a = 5; //error as 5 is data type number
	NUMBER b = 10;
	ECHO c;

	LOOP(ECHO i = 0; i < a; i++)
	{
		WHILST(i < b)
		{
			CONDITION(i % 2 == 0)
			{
				ECHO i;
			}
			ELSE
			{
				INTERRUPT;
			}
		}
	}

	ECHO result = someFunction(a, b);
	ECHO anotherResult = anotherFunction();

	RESUME;
}
