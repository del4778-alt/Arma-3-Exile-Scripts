WB_baseTaxRatePerZone = 250;
WB_zoneTierMultiplier = [1.0, 1.6, 3.5];

WB_treasury = createHashMapFromArray [
    ["KAV", 5000],
    ["PYR", 5000],
    ["ATH", 5000],
    ["CIV", 5000]
];

WB_relations = createHashMapFromArray [
    ["KAV",[["PYR",-10],["ATH",0],["CIV",10]]],
    ["PYR",[["KAV",-10],["ATH",10],["CIV",0]]],
    ["ATH",[["KAV",0],["PYR",10],["CIV",15]]],
    ["CIV",[["KAV",10],["PYR",0],["ATH",15]]]
];
