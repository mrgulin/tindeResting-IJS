import master

if __name__ == "__main__":
    # p_l = {"BPA": {"BLANK": ("BLANK",), "CONTROL": ("QC1",), "SAMPLE": ("BPA", )}}
    # BPA1 = master.GenerateList("Mzinput/MzMine_Output_PlasmaBPA_Project1_New.csv", p_l, "../data/python_out")
    # BPA1.merged_algorithm()

    # p_l = {"BPA": {"BLANK": ("BLANK",), "CONTROL": ("QC1",), "SAMPLE": ("BPA",)}}
    # BPA1 = master.GenerateList("Mzinput/MzMine_Output_PlasmaBPA_Project1_New_gapFill.csv", p_l, "../data/MzMine_Output_PlasmaBPA_Project1_New_gapFill_out")
    # BPA1.merged_algorithm()
    if False:
        p_l = {"BPA": {"BLANK": ("BLANK",), "CONTROL": ("BPA.0",), "SAMPLE": ("BPA",)}}
        BPA1 = master.GenerateList("Mzinput/MzMine_Output_PlasmaBPA_Project1_New_gapFill_v2.csv", p_l,
                                   "../data/MzMine_Output_PlasmaBPA_Project1_New_gapFill_out_v2")
        BPA1.merged_algorithm()

    if True:
        p_l_BPS = {"BPS": {"BLANK": ("BLANK",), "CONTROL": ("BPS.0",), "SAMPLE": ("BPS",)}}
        BPA1 = master.GenerateList("Mzinput/MzMine_Output_PlasmaBPS_Project1.csv", p_l_BPS,
                                   "../data/MzMine_Output_PlasmaBPS_v1")
        BPA1.merged_algorithm()