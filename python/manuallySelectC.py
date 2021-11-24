file=open("BPF_mz_THIRD.csv", "r")
from collections import OrderedDict 
###MENJAJ 0_5 z 0.5!!!!

text=file.readlines()
#text=[i.replace("_", ".") for i in text]
text=[i.strip().split(",")[:-1] for i in text]
text[0]=[i.replace(".mzdata.xml Peak height", "") for i in text[0]]
for i in range(len(text)):
    text[i].insert(1, 0)
    text[i]=text[i][0:4]+[0,0,0,0,0]+text[i][4:]
#B je kontrola od A in D je kotrola od C
#B je kontrola od A in D je kotrola od C
#text->razmreje med vzorcem in blanki
#text2->urejen seznam
a=[]
ac=[]
c=[]
cc=[]
ab=[]
cb=[]

#SUBSAMPLE:
lA=["BLANK-A","BPF-A1", "BPF-A2", "BPF-B"]
lC=["BLANK-C","BPF-C1", "BPF-C2", "BPF-D"]
#any(part in  for part in lA)

#mode=input("katere hočeš subsample-at?; A, C, ACN (nonaveraged)")
mode="C"
for i in range(9,len(text[0])):
    splitted=text[0][i].split("-")
    if splitted[1][0]=="A" and splitted[0]=="BPF":
        a.append(i)
    if splitted[1][0]=="B" and splitted[0]=="BPF":
        ac.append(i)
    if splitted[1][0]=="C" and splitted[0]=="BPF":
        c.append(i)
    if splitted[1][0]=="D" and splitted[0]=="BPF":
        cc.append(i)
    if splitted[1][0]=="A" and splitted[0]!="BPF":
        ab.append(i)
    if splitted[1][0]=="C" and splitted[0]!="BPF":
        cb.append(i)
    time=splitted[-2]
    splitted.remove(splitted[-2])
    text[0][i]="-".join(splitted)+"_"+time
    #print(text[0][i])
def aver(lind, lval):
    val=0
    for ind in lind:
        val+=float(lval[ind])
    if val==0:
        return 1E-10
    return val/len(lind)
for i in range(1,len(text)):
    text[i][1]=text[i][0]
    if mode=="A":
        text[i][5]=aver(ac,text[i])/aver(a,text[i])
        text[i][6]=aver(ab,text[i])/aver(a,text[i])
    elif mode=="C":
        text[i][5]=aver(cc,text[i])/aver(c,text[i])
        text[i][6]=aver(cb,text[i])/aver(c,text[i])
    else:
        text[i][5]=min(aver(ac,text[i])/aver(a,text[i]), aver(cc,text[i])/aver(c,text[i]))
        text[i][6]=min(aver(ab,text[i])/aver(a,text[i]), aver(cb,text[i])/aver(c,text[i]))


d1=dict()
for i in range(9,len(text[0])):

    spl=str(text[0][i]).split("_")
    spl[0]=spl[0].upper()
    if spl[0] not in d1:
        d1[spl[0]]=[(i, spl[1])]
    else:
        d1[spl[0]].append((i, spl[1]))
for i in d1.keys():
    d1[i]=sorted(d1[i], key=lambda x: float(x[1]))
l1 = [(k, v) for k, v in d1.items()] 
text2=[]
for i in range(len(text)):
    text2.append([])
    text2[i]=text[i][0:9]
    for x in l1:
       for y in x[1]:
           text2[i].append(text[i][y[0]])
text20=[[]]
text20[0]=text[i][1:9]
for x in l1:
       for y in x[1]:
           text20[0].append(text[i][y[0]])
for i in range(len(text)):
    text20.append([])
    text20[i]=text[i][1:9]
    for x in l1:
       for y in x[1]:
           text20[i].append(text[i][y[0]])

    
d1=OrderedDict()





for i in range(9,len(text2[0])):

    spl=str(text2[0][i]).replace("-N2","").replace("-N1","").upper()
    if any(part in spl for part in lA) and mode=="A":
        if spl not in d1:
            d1[spl]=[i]
        else:
            d1[spl].append(i)
    if any(part in spl for part in lC) and mode=="C":
        if spl not in d1:
            d1[spl]=[i]
        else:
            d1[spl].append(i)

l1 = [(k, v) for k, v in d1.items()]
text3=[[]]
for i in range(1,len(text)):
    text3.append([])
    text3[i]=text2[i][1:9] #PAZI TO
    for x in l1:
        su=0
        for y in x[1]:
           su+=float(text2[i][y])
        su=su/len(x[1])
        text3[i].append(su)
text3[0]=text2[0][0:9]
for x in l1:
    text3[0].append(x[0])
text3[0]=["index","mzmed","rtmed","matched","qSvsMB","qSvsNC","modelPredicted","predictVal"]+text3[0][9:]
colnames=[]
for i in range(len(text3[0])):
    if "_" in text3[0][i]:
        splitted=text3[0][i].split("_")
    else:
        splitted=["/","/"]
    colnames.append(splitted[0])
d2=dict() #največje vrednosti
d3=dict() #seznam vrednosti
d4=dict() #povprečja



#for i in range(1,6):
for i in range(1,len(text3)):
    d2=dict() #največje vrednosti
    d3=dict() #seznam vrednosti
    d4=dict() #povprečja
    for j in range(8,len(text3[0])):
        text3[i][j]=float(text3[i][j])        
        if colnames[j] not in d2:
            d2[colnames[j]]=(j, text3[i][j])
        elif text3[i][j]>d2[colnames[j]][1]:
            d2[colnames[j]]=(j, text3[i][j])

        if colnames[j] not in d3:
            d3[colnames[j]]=[text3[i][j]]
        else:
            d3[colnames[j]].append(text3[i][j])
    for k,v in d3.items():
        d4[k]=sum(v)/len(v)
    index1=(d2["BPF-C1"][1]+d2["BPF-C2"][1])/(d4["BLANK-C"]*2+0.001)
    index1_1=(d2["BPF-C1"][1]+d2["BPF-C2"][1])/(2*d4["BPF-D"]+0.001)
    index2=(d2["BPF-C1"][1]+d2["BPF-C2"][1])/(d4["BPF-C1"]+d4["BPF-C2"]+0.001)
    index3=(d2["BPF-C1"][1]+d2["BPF-C2"][1])/2
    index4=(float(text3[i][text3[0].index("BPF-C1_0")])+float(text3[i][text3[0].index("BPF-C2_0")]))/2
    index4_1=(text3[i][text3[0].index("BPF-C1_0")]+text3[i][text3[0].index("BPF-C2_0")])/(d4["BPF-C1"]+d4["BPF-C2"]+0.001)
    text3[i][3]=index1
    text3[i][6]=index2
    text3[i][7]=index3
    text3[i][2]=index4
    text3[i][8]=index1_1
    text3[i][9]=index4_1
text3[0][3]="index1"
text3[0][6]="index2"
text3[0][7]="index3"
text3[0][2]="index4"
text3[0][8]="index1.1"
text3[0][9]="index4.1"
text4=[text3[0][:10]]
#index1,intex2, q1,q2
pogoji=[1.5,1,1000,500,1,1]
list123=[0,0,0,0,0,0]
for i in range(1,len(text3)):
    if text3[i][3]>pogoji[0] and text3[i][8]>pogoji[0]:
        list123[0]+=1
        if text3[i][6]>pogoji[1]:
            list123[1]+=1
            if text3[i][7]>pogoji[2]:
                list123[2]+=1
                if text3[i][2]<pogoji[3]and text3[i][9]<1:  #!!!!!
                    list123[3]+=1
                    if text3[i][4]<pogoji[4]:
                        list123[4]+=1
                        if text3[i][5]<pogoji[5]:
                            list123[5]+=1
                            text4.append(text3[i][:10])
print(list123)
print("Index1: ", list123[0]/len(text3)*100,"%")
print("Index2: ", list123[1]/list123[0]*100,"%")
print("Index3: ", list123[2]/list123[1]*100,"%")
print("Index4: ", list123[3]/list123[2]*100,"%")
print("q1: ", list123[4]/list123[3]*100,"%")
print("q2: ", list123[5]/list123[4]*100,"%")
print(len(text4),len(text3),len(text4)/len(text3)*100,"%")


text[0]=["index","mzmed","rtmed","matched","qSvsMB","qSvsNC","modelPredicted","predictVal"]+text[0][9:]
text2[0]=["index","mzmed","rtmed","matched","qSvsMB","qSvsNC","modelPredicted","predictVal"]+text2[0][9:]

text20[0]=["index","mzmed","rtmed","matched","qSvsMB","qSvsNC","modelPredicted","predictVal"]+text20[0][8:]
input("PAZI DA NE PREPIŠEŠ!!! trenutno so q-ji samo od AAAA!!!!!")
"""if mode=="A" or mode=="C":
    ret=text3
else:
    ret=text20"""
with open('shinyPosDataKRITERIJI'+mode+'.txt', 'w') as outfile:  # also, tried mode="rb"
    for s in text4:
        s = ','.join(str(v) for v in s)
        outfile.write("%s\n" % s)

