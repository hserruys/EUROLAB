*********************************************************************************
* unemployment.do																*
*																				*
* Last Update: 12/06/2019 E.N.													*                           
*********************************************************************************
if "${country}" == "it"{
	replace regunp = 0.041 if drgn2 == 1 & dgn == 0
	replace regunp = 0.041 if drgn2 == 2 & dgn == 0 // missing value, I use the same as for Piemonte
	replace regunp = 0.041 if drgn2 == 3 & dgn == 0
	replace regunp = 0.029 if drgn2 == 4 & dgn == 0
	replace regunp = 0.041 if drgn2 == 5 & dgn == 0
	replace regunp = 0.055 if drgn2 == 6 & dgn == 0
	replace regunp = 0.041 if drgn2 == 7 & dgn == 0
	replace regunp = 0.059 if drgn2 == 8 & dgn == 0
	replace regunp = 0.037 if drgn2 == 9 & dgn == 0
	replace regunp = 0.063 if drgn2 == 10 & dgn == 0
	replace regunp = 0.070 if drgn2 == 11 & dgn == 0
	replace regunp = 0.056 if drgn2 == 12 & dgn == 0
	replace regunp = 0.084 if drgn2 == 13 & dgn == 0
	replace regunp = 0.084 if drgn2 == 14 & dgn == 0
	replace regunp = 0.129 if drgn2 == 15 & dgn == 0
	replace regunp = 0.147 if drgn2 == 16 & dgn == 0
	replace regunp = 0.148 if drgn2 == 17 & dgn == 0
	replace regunp = 0.131 if drgn2 == 18 & dgn == 0
	replace regunp = 0.134 if drgn2 == 19 & dgn == 0
	replace regunp = 0.144 if drgn2 == 20 & dgn == 0
	replace regunp = 0.123 if drgn2 == 21 & dgn == 0

	replace regunp = 0.025 if drgn2 == 1 & dgn == 1
	replace regunp = 0.025 if drgn2 == 2 & dgn == 1 // missing value, I use the same as for Piemonte
	replace regunp = 0.022 if drgn2 == 3 & dgn == 1
	replace regunp = 0.014 if drgn2 == 4 & dgn == 1
	replace regunp = 0.014 if drgn2 == 5 & dgn == 1
	replace regunp = 0.018 if drgn2 == 6 & dgn == 1
	replace regunp = 0.021 if drgn2 == 7 & dgn == 1
	replace regunp = 0.026 if drgn2 == 8 & dgn == 1
	replace regunp = 0.022 if drgn2 == 9 & dgn == 1
	replace regunp = 0.024 if drgn2 == 10 & dgn == 1
	replace regunp = 0.022 if drgn2 == 11 & dgn == 1
	replace regunp = 0.027 if drgn2 == 12 & dgn == 1
	replace regunp = 0.046 if drgn2 == 13 & dgn == 1
	replace regunp = 0.034 if drgn2 == 14 & dgn == 1
	replace regunp = 0.057 if drgn2 == 15 & dgn == 1
	replace regunp = 0.082 if drgn2 == 16 & dgn == 1
	replace regunp = 0.082 if drgn2 == 17 & dgn == 1
	replace regunp = 0.061 if drgn2 == 18 & dgn == 1
	replace regunp = 0.093 if drgn2 == 19 & dgn == 1
	replace regunp = 0.087 if drgn2 == 20 & dgn == 1
	replace regunp = 0.068 if drgn2 == 21 & dgn == 1
}

if "${country}" == "es"{
	replace	regunp	=	32.14	if 	drgn2 ==	61	&dgn==0
	replace	regunp	=	17.84	if 	drgn2 ==	24	&dgn==0
	replace	regunp	=	16.32	if 	drgn2 ==	12	&dgn==0
	replace	regunp	=	14.43	if 	drgn2 ==	53	&dgn==0
	replace	regunp	=	28.00	if 	drgn2 ==	70	&dgn==0
	replace	regunp	=	15.51	if 	drgn2 ==	13	&dgn==0
	replace	regunp	=	17.90	if 	drgn2 ==	41	&dgn==0
	replace	regunp	=	28.22	if 	drgn2 ==	42	&dgn==0
	replace	regunp	=	16.93	if 	drgn2 ==	51	&dgn==0
	replace	regunp	=	22.58	if 	drgn2 ==	52	&dgn==0
	replace	regunp	=	32.39	if 	drgn2 ==	43	&dgn==0
	replace	regunp	=	17.82	if 	drgn2 ==	11	&dgn==0
	replace	regunp	=	16.47	if 	drgn2 ==	30	&dgn==0
	replace	regunp	=	23.00	if 	drgn2 ==	62	&dgn==0
	replace	regunp	=	14.26	if 	drgn2 ==	22	&dgn==0
	replace	regunp	=	13.15	if 	drgn2 ==	21	&dgn==0
	replace	regunp	=	15.15	if 	drgn2 ==	23	&dgn==0
	replace	regunp	=	31.95	if 	drgn2 ==	63	&dgn==0
	replace	regunp	=	37.66	if 	drgn2 ==	64	&dgn==0

		
	replace	regunp	=	26.20	if 	drgn2 ==	61	&dgn==1
	replace	regunp	=	12.11	if 	drgn2 ==	24	&dgn==1
	replace	regunp	=	18.83	if 	drgn2 ==	12	&dgn==1
	replace	regunp	=	13.43	if 	drgn2 ==	53	&dgn==1
	replace	regunp	=	24.38	if 	drgn2 ==	70	&dgn==1
	replace	regunp	=	14.35	if 	drgn2 ==	13	&dgn==1
	replace	regunp	=	14.12	if 	drgn2 ==	41	&dgn==1
	replace	regunp	=	19.96	if 	drgn2 ==	42	&dgn==1
	replace	regunp	=	14.61	if 	drgn2 ==	51	&dgn==1
	replace	regunp	=	18.91	if 	drgn2 ==	52	&dgn==1
	replace	regunp	=	23.74	if 	drgn2 ==	43	&dgn==1
	replace	regunp	=	16.54	if 	drgn2 ==	11	&dgn==1
	replace	regunp	=	15.01	if 	drgn2 ==	30	&dgn==1
	replace	regunp	=	17.31	if 	drgn2 ==	62	&dgn==1
	replace	regunp	=	10.92	if 	drgn2 ==	22	&dgn==1
	replace	regunp	=	12.10	if 	drgn2 ==	21	&dgn==1
	replace	regunp	=	12.19	if 	drgn2 ==	23	&dgn==1
	replace	regunp	=	20.15	if 	drgn2 ==	63	&dgn==1
	replace	regunp	=	26.12	if 	drgn2 ==	64	&dgn==1

	
}

if "${country}" == "el"{
	replace	regunp	=	15.9	if drgn2 ==	11
	replace	regunp	=	20.7	if drgn2 ==	12
	replace	regunp	=	27		if drgn2 ==	13
	replace	regunp	=	20.1	if drgn2 ==	14
	replace	regunp	=	18.3	if drgn2 ==	21
	replace	regunp	=	15.9	if drgn2 ==	22
	replace	regunp	=	24.1	if drgn2 ==	23
	replace	regunp	=	18.9	if drgn2 ==	24
	replace	regunp	=	14.4	if drgn2 ==	25
	replace	regunp	=	19.9	if drgn2 ==	30
	replace	regunp	=	22.3	if drgn2 ==	41
	replace	regunp	=	16.9	if drgn2 ==	42
	replace	regunp	=	13.4	if drgn2 ==	43
}
