import master

if __name__ == "__main__":
    # p_l = {"BPA": {"BLANK": ("BLANK",), "CONTROL": ("QC1",), "SAMPLE": ("BPA", )}}
    # BPA1 = master.GenerateList("Mzinput/MzMine_Output_PlasmaBPA_Project1_New.csv", p_l, "../data/python_out")
    # BPA1.merged_algorithm()

    p_l = {"BPA": {"BLANK": ("BLANK",), "CONTROL": ("QC1",), "SAMPLE": ("BPA",)}}
    BPA1 = master.GenerateList("Mzinput/MzMine_Output_PlasmaBPA_Project1_New_gapFill.csv", p_l, "../data/MzMine_Output_PlasmaBPA_Project1_New_gapFill_out")
    BPA1.merged_algorithm()