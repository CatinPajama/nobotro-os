

int strlen(char *str)
{
	int len = 0;
	while ((*str++) != '\0')
		len++;
	return len;
}

int strcmp(const char *s1, const char *s2)
{
	int i = 0;
	while (s1[i] != '\0' && s2[i] != '\0')
	{
		char c1 = s1[i];
		char c2 = s2[i];

		if (c1 >= 'A' && c1 <= 'Z')
		{
			c1 = c1 + 32;
		}
		if (c2 >= 'A' && c2 <= 'Z')
		{
			c2 = c2 + 32;
		}

		if (c1 != c2)
		{
			return 1;
		}

		i++;
	}

	return s1[i] - s2[i];
}

void strcpy(char *buf_to, char *buf_from)
{

	char a = 0;
	while ((a = *buf_from++) != '\0')
	{
		*buf_to++ = a;
	}
}

void reverse(char s[])
{
	int i, j;
	char c;

	for (i = 0, j = strlen(s) - 1; i < j; i++, j--)
	{
		c = s[i];
		s[i] = s[j];
		s[j] = c;
	}
}

char *strtok(char *str, char delim)
{
	while (*str != delim && *str != '\0')
		str++;
	return str;
}