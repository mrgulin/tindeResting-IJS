file = open("Mzinput/" + "BPS_mz_1E4_FIRST_AREA.csv", "r")
from collections import OrderedDict

###MENJAJ 0_5 z 0.5!!!!

text = file.readlines()
text = [i.replace("_", ".") for i in text]
text = [i.strip().split(",")[:-1] for i in text]
text[0] = [i.replace(".mzdata.xml Peak height", "") for i in text[0]]
text[0] = [i.replace(".mzdata.xml Peak area", "") for i in text[0]]
for i in range(len(text)):
    text[i].insert(1, 0)
    text[i] = text[i][0:4] + [0, 0, 0, 0, 0] + text[i][4:]
# B je kontrola od A in D je kotrola od C
# B je kontrola od A in D je kotrola od C
# text->razmreje med vzorcem in blanki
# text2->urejen seznam
a = []
ac = []
c = []
cc = []
ab = []
cb = []

# SUBSAMPLE:
lA = ["BLANK-A", "BPF-A1", "BPF-A2", "BPF-B"]
lC = ["BLANK-C", "BPF-C1", "BPF-C2", "BPF-D"]
# any(part in  for part in lA)

mode = input("katere hočeš subsample-at?; A, C, ACN (nonaveraged)")
for i in range(9, len(text[0])):
    splitted = text[0][i].split("-")
    if splitted[1][0] == "A" and splitted[0] == "BPF":
        a.append(i)
    if splitted[1][0] == "B" and splitted[0] == "BPF":
        ac.append(i)
    if splitted[1][0] == "C" and splitted[0] == "BPF":
        c.append(i)
    if splitted[1][0] == "D" and splitted[0] == "BPF":
        cc.append(i)
    if splitted[1][0] == "A" and splitted[0] != "BPF":
        ab.append(i)
    if splitted[1][0] == "C" and splitted[0] != "BPF":
        cb.append(i)
    time = splitted[-2]
    splitted.remove(splitted[-2])
    text[0][i] = "-".join(splitted) + "_" + time
    # print(text[0][i])


def aver(lind, lval):
    val = 0
    for ind in lind:
        val += float(lval[ind])
    if val == 0:
        return 1E-10
    return val / len(lind)


for i in range(1, len(text)):
    text[i][1] = text[i][0]
    if mode == "A":
        text[i][5] = aver(ac, text[i]) / aver(a, text[i])
        text[i][6] = aver(ab, text[i]) / aver(a, text[i])
    elif mode == "C":
        text[i][5] = aver(cc, text[i]) / aver(c, text[i])
        text[i][6] = aver(cb, text[i]) / aver(c, text[i])
    else:
        text[i][5] = min(aver(ac, text[i]) / aver(a, text[i]), aver(cc, text[i]) / aver(c, text[i]))
        text[i][6] = min(aver(ab, text[i]) / aver(a, text[i]), aver(cb, text[i]) / aver(c, text[i]))

d1 = dict()
for i in range(9, len(text[0])):

    spl = str(text[0][i]).split("_")
    spl[0] = spl[0].upper()
    if spl[0] not in d1:
        d1[spl[0]] = [(i, spl[1])]
    else:
        d1[spl[0]].append((i, spl[1]))
for i in d1.keys():
    d1[i] = sorted(d1[i], key=lambda x: float(x[1]))
l1 = [(k, v) for k, v in d1.items()]
text2 = []
for i in range(len(text)):
    text2.append([])
    text2[i] = text[i][0:9]
    for x in l1:
        for y in x[1]:
            text2[i].append(text[i][y[0]])
text20 = [[]]
text20[0] = text[i][1:9]
for x in l1:
    for y in x[1]:
        text20[0].append(text[i][y[0]])
for i in range(len(text)):
    text20.append([])
    text20[i] = text[i][1:9]
    for x in l1:
        for y in x[1]:
            text20[i].append(text[i][y[0]])

d1 = OrderedDict()

for i in range(9, len(text2[0])):

    spl = str(text2[0][i]).replace("-N2", "").replace("-N1", "").upper()
    if any(part in spl for part in lA) and mode == "A":
        if spl not in d1:
            d1[spl] = [i]
        else:
            d1[spl].append(i)
    if any(part in spl for part in lC) and mode == "C":
        if spl not in d1:
            d1[spl] = [i]
        else:
            d1[spl].append(i)

l1 = [(k, v) for k, v in d1.items()]
text3 = [[]]
for i in range(1, len(text)):
    text3.append([])
    text3[i] = text2[i][1:9]  # PAZI TO
    for x in l1:
        su = 0
        for y in x[1]:
            su += float(text2[i][y])
        su = su / len(x[1])
        text3[i].append(su)
text3[0] = text2[0][0:9]
for x in l1:
    text3[0].append(x[0])

text[0] = ["index", "mzmed", "rtmed", "matched", "qSvsMB", "qSvsNC", "modelPredicted", "predictVal"] + text[0][9:]
text2[0] = ["index", "mzmed", "rtmed", "matched", "qSvsMB", "qSvsNC", "modelPredicted", "predictVal"] + text2[0][9:]
text3[0] = ["index", "mzmed", "rtmed", "matched", "qSvsMB", "qSvsNC", "modelPredicted", "predictVal"] + text3[0][9:]
text20[0] = ["index", "mzmed", "rtmed", "matched", "qSvsMB", "qSvsNC", "modelPredicted", "predictVal"] + text20[0][8:]
input("PAZI DA NE PREPIŠEŠ!!! trenutno so q-ji samo od AAAA!!!!!")
if mode == "A" or mode == "C":
    ret = text3
else:
    ret = text20
with open('shinyPosData' + "S_Area_" + mode + '.txt', 'w') as outfile:  # also, tried mode="rb"
    for s in ret:
        s = ','.join(str(v) for v in s)
        outfile.write("%s\n" % s)
