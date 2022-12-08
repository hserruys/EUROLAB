// AT: Vienna + Niederoesterreich + Burgenland (region 1)
if "${country}" == "at" {
    *quietly replace reg = 1 if reg1 == 1
}
// BE: Brussel (1)
if "${country}" == "be" {
    *quietly replace reg = 1 if reg1 == 1
}
/* FI: Helsinki (1)
if "${country}" == "fi" {
    quietly replace reg = 1 if reg1 == 1 
}*/
// FR: Paris (5)
if "${country}" == "fr" {
    quietly replace reg = 1 if reg5==1 
}
// DE
if "${country}" == "de" {
    quietly replace reg = 1 if drgn1 == 1
}
// EL: Athens (3)
if "${country}" == "el" {
    quietly replace reg = 1 if drgn2 ==  30
}
/* IE: Dublin (1)
if "${country}" == "ie" {
    quietly replace reg = 1 if reg1==0 
}*/
if "${country}" == "it" {
    quietly replace reg = 3 if drgn2==3
}
/* PT: Lisboa (3)
if "${country}" == "pt" {
    quietly replace reg = 1 if reg3==1 
}*/
// ES: Catalunya (5)
if "${country}" == "es" {
    quietly replace reg = regunp
}
if "${country}" == "mt" {
    quietly replace reg = 1 if reg1 == 1
}
// UK: London (7)
if "${country}" == "uk" {
    quietly replace reg = 1 if reg7 ==1  
}
// SE: Stockholm (1)
if "${country}" == "se" {
    quietly replace reg = 1 if reg1 == 1 
}
// EE: Estonia
if "${country}" == "ee" {
    quietly replace reg = 1 if reg1 == 1 
}
// HU: Central Hungary (1)
if "${country}" == "hu" {
    quietly replace reg = 1 if reg1 == 1 
}
// PL: Central (1)
if "${country}" == "pl" {
    quietly replace reg = 1 if reg1 == 1 
}
