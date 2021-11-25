from collections import OrderedDict
import numpy as np

def transform_time(string1):
    string1 = string1.replace("_", ".")
    return float(string1)



def aver(lind, lval):
    val = 0
    for ind in lind:
        val += float(lval[ind])
    if val == 0:
        return 1E-10
    return val / len(lind)

def minimalNumber(x):
    if type(x) is str:
        if x == '':
            x = 0
    f = float(x)
    if f.is_integer():
        return int(f)
    else:
        return f

class Generate_list:
    def __init__(self, filename, limit):
        np.set_printoptions(precision=2)
        self.file_name = filename
        self.table = []
        self.header = []
        self.limit = limit
        self.parameter_list = {"A": {"blank": ("BLANK-A",), "control": ("BPF-B",), "sample": ("BPF-A1", "BPF-A2")},
                               "C": {"blank": ("BLANK-C",), "control": ("BPF-D",), "sample": ("BPF-C1", "BPF-C2")}}
        # TODO: change parameter list into input
        self.new_header = []
        self.column_index_dict = dict()
        self.ratio_dict = OrderedDict()
        self.grouped_index_dict = OrderedDict()


    def get_table(self):
        '''
        Reads file into table and saves table into self.table
        :return: 
        '''
        file = open(self.file_name, "r")
        data = file.readlines()
        data = [i.replace("_", ".") for i in data]
        data = [i.strip().split(",")[:-1] for i in data]
        data[0] = [i.replace(".mzdata.xml Peak height", "") for i in data[0]]
        data[0] = [i.replace(".mzdata.xml Peak area", "") for i in data[0]]
        for i in range(len(data)):
            if i == 0:
                data[i].insert(1, '0')
                data[i] = data[i][0:4] + ['0', '0', '0', '0', '0'] + data[i][4:]
            else:
                data[i] = [float(j) for j in data[i]]
                data[i].insert(1, 0)
                data[i] = data[i][0:4] + [0, 0, 0, 0, 0] + data[i][4:]
        self.table = data[1:]
        self.header = data[0]

    def get_sample_names(self, extra_vars=9):
        for key1, dict1 in self.parameter_list.items():
            if key1 not in self.column_index_dict:
                self.column_index_dict[key1] = dict()
            for key2, tup_name in dict1.items():
                if key2 not in self.column_index_dict[key1]:
                    self.column_index_dict[key1][key2] = {"index": [], "name": [], "time": [], "aliquot": []}
                    if key2 == "sample":
                        self.column_index_dict[key1][key2]['parallel'] = []
                for col_name in tup_name:
                    for i, col_name_text in enumerate(self.header):
                        split = col_name_text.split("-")
                        if col_name in col_name_text:
                            self.column_index_dict[key1][key2]['index'].append(i)
                            self.column_index_dict[key1][key2]['name'].append(col_name_text)
                            self.column_index_dict[key1][key2]['aliquot'].append(
                                split[-1])  # watch out: name based algorithm!
                            self.column_index_dict[key1][key2]['time'].append(transform_time(split[-2]))
                            if key2 == "sample":
                                self.column_index_dict[key1][key2]['parallel'].append(split[1])

        first_row_updated = header.copy()
        for i in range(extra_vars, len(header)):
            split = header[i].split("-")
            time = split[-2]
            split.remove(split[-2])
            first_row_updated[i] = "-".join(split) + "_" + time

        self.new_header = np.array(first_row_updated)

    def calculate_ratios(self):
        self.ratio_dict["both"] = np.zeros(shape=(len(self.table), 2))
        for key in self.parameter_list.keys():
            self.ratio_dict[key] = np.zeros(shape=(len(self.table), 2))
        for i in range(len(self.table)):
            self.table[i][1] = self.table[i][0]
            f1_list = []
            f2_list = []
            for key in self.parameter_list.keys():
                subdict = self.column_index_dict[key]
                f1 = aver(subdict["control"]['index'], self.table[i]) / aver(subdict["sample"]['index'], self.table[i])
                f2 = aver(subdict["blank"]['index'], self.table[i]) / aver(subdict["sample"]['index'], self.table[i])
                self.ratio_dict[key][i][0] = f1
                self.ratio_dict[key][i][1] = f2
                f1_list.append(f1)
                f2_list.append(f2)
            self.ratio_dict['both'][i][0] = min(f1_list)
            self.ratio_dict['both'][i][1] = min(f2_list)





    def sort_columns(self):
        for key1, d1 in self.column_index_dict.items():
            for key2, value in d1.items():
                subdict = self.column_index_dict[key1][key2]
                subdict['index'] = np.array(subdict['index'], dtype=int)
                subdict['name'] = np.array(subdict['name'])
                subdict['aliquot'] = np.array(subdict['aliquot'])
                subdict['time'] = np.array(subdict['time'])
                if key2 == "sample":
                    subdict['parallel'] = np.array(subdict['parallel'])
                    # below we set if we want N1 t1 N2 t1 or N1 t1 N1 t2 .. N2 t1 N2 t2
                    ind = np.lexsort((subdict['aliquot'], subdict['time'], subdict['parallel']))
                else:
                    ind = np.lexsort((subdict['aliquot'], subdict['time']))
                [subdict['aliquot'][i] + ", " + str(self.column_index_dict[key1][key2]['time'][i]) for i in ind]
                subdict['index'] = subdict['index'][ind]
                subdict['name'] = subdict['name'][ind]
                subdict['aliquot'] = subdict['aliquot'][ind]
                subdict['time'] = subdict['time'][ind]
                if key2 == "sample":
                    subdict['parallel'] = subdict['parallel'][ind]


    def group_aliquots(self):
        # Limit options: e.g., 'type': ('A')
        for key1, d1 in self.column_index_dict.items():
            if 'type' in self.limit:
                if key1 not in self.limit['type']:
                    continue
            for key2, subdict in d1.items():
                for j, sample_ind in enumerate(subdict['index']):
                    if key2 == "sample":
                        new_sample_name = f"{key2}_{subdict['parallel'][j]}_{minimalNumber(subdict['time'][j])}"

                    else:
                        new_sample_name = f"{key1}_{key2}_{minimalNumber(subdict['time'][j])}"
                    if new_sample_name in self.grouped_index_dict:
                        self.grouped_index_dict[new_sample_name].append(sample_ind)
                    else:
                        self.grouped_index_dict[new_sample_name] = [sample_ind]
                        print(new_sample_name)


def average_aliquots(data, extra_vars=9):
    global header
    grouped_header = header[:extra_vars]
    grouped_data = np.zeros(shape=(len(data), len(self.grouped_index_dict)))

    for i, line in enumerate(data):
        j = 0
        for group_name, index_list in self.grouped_index_dict.items():
            if i == 0:
                grouped_header.append(group_name)
            grouped_data[i][j] = aver(index_list, line)

            j += 1

    return grouped_header, np.concatenate(([i[:extra_vars] for i in data], grouped_data), axis=1)


if __name__ == "__main__":
    header, table = get_table("Mzinput/BPF_mz_Strict.csv")
    get_sample_names(header)
    calculate_ratios(table)

    # print(np.concatenate((self.ratio_dict["A"], self.ratio_dict["C"], self.ratio_dict["both"]), axis=1))
    sort_columns()
    group_aliquots(limit={'type': 'C'})
    # print(self.grouped_index_dict)
    grouped_table_header, grouped_table = average_aliquots(table, extra_vars=9)
    print(grouped_table_header)
