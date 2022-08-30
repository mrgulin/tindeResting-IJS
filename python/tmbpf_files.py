import master
import sys
sys.path.extend([r'C:\Users\tinc9\Documents\IJS-offline\Python scripts'])
import mzproject.merge_tables

samples = ["TMBPF_Blank_D_Day1", "TMBPF_Blank_D_Day6", "TMBPF_Blank_D_Day2", "TMBPF_Blank_D_Day5", "TMBPF_Blank_D_Day9", "TMBPF_Blank_D_Day3", "TMBPF_Blank_D_Day0", "TMBPF_D1_day0", "TMBPF_Blank_D_Day11", "TMBPF_Blank_D_Day4", "TMBPF_Blank_D_Day10", "TMBPF_Blank_D_Day14", "TMBPF_Blank_D_Day7", "TMBPF_Blank_D_Day12", "TMBPF_Blank_D_Day13", "TMBPF_D1_day4", "TMBPF_Blank_D_Day15", "TMBPF_D1_day1", "TMBPF_D1_day6", "TMBPF_D1_day3", "TMBPF_D1_day9", "TMBPF_D1_day2", "TMBPF_D1_day7", "TMBPF_D1_day5", "TMBPF_D2_day1", "TMBPF_D2_day0", "TMBPF_D2_day4", "TMBPF_D2_day5", "TMBPF_D2_day7", "TMBPF_D2_day11", "TMBPF_D1_day11", "TMBPF_D2_day12", "TMBPF_D2_day14", "TMBPF_D1_day10", "TMBPF_D1_day13", "TMBPF_D1_day12", "TMBPF_D2_day13", "TMBPF_D1_day14", "TMBPF_D2_day8", "TMBPF_D2_day10", "TMBPF_D3_day9", "TMBPF_D2_day6", "TMBPF_D3_day0", "TMBPF_D3_day2", "TMBPF_D3_day1", "TMBPF_D2_day9", "TMBPF_D3_day7", "TMBPF_D2_day15", "TMBPF_D3_day10", "TMBPF_D3_day12", "TMBPF_D3_day15", "TMBPF_D3_day14", "TMBPF_D3_day4", "TMBPF_D3_day6", "TMBPF_D3_day5", "TMBPF_D3_day11", "TMBPF_D3_day8", "TMBPF_D3_day13", "TMBPF_Blank_D_Day8", "TMBPF_D3_day3", "TMBPF_D2_day3", "TMBPF_D2_day2", "TMBPF_D1_day8",
"Blank_A_day7", "Blank_A_day6", "Blank_A_day11", "Blank_A_day5", "Blank_A_day2", "Blank_A_day8", "Blank_A_day4", "Blank_A_day9", "Blank_A_day10", "Blank_A_day3", "Blank_A_day0", "Blank_A_day1", "Blank_A_day13", "Blank_A_day15", "TMBPF_A1_day6", "TMBPF_A1_day3", "TMBPF_A1_day5", "TMBPF_A1_day2", "TMBPF_A1_day7", "Blank_A_day14", "Blank_A_day12", "TMBPF_A1_day4", "TMBPF_A1_day0", "TMBPF_A1_day1", "TMBPF_A1_day9", "TMBPF_A1_day10", "TMBPF_A1_day11", "TMBPF_A1_day12", "TMBPF_A1_day14", "TMBPF_A1_day8", "TMBPF_A1_day15", "TMBPF_A2_day3", "TMBPF_A2_day2", "TMBPF_A2_day1", "TMBPF_A1_day13", "TMBPF_A2_day0", "TMBPF_A2_day7", "TMBPF_A2_day9", "TMBPF_A2_day10", "TMBPF_A2_day5", "TMBPF_A2_day11", "TMBPF_A2_day8", "TMBPF_A2_day6", "TMBPF_A2_day13", "TMBPF_A2_day12", "TMBPF_A2_day14", "TMBPF_A2_day15", "TMBPF_A2_day4", "TMBPF_A3_day10", "TMBPF_A3_day1", "TMBPF_A3_day11", "TMBPF_A3_day9", "TMBPF_A3_day5", "TMBPF_A3_day8", "TMBPF_A3_day7", "TMBPF_A3_day0", "TMBPF_A3_day2", "TMBPF_A3_day4", "TMBPF_A3_day3", "TMBPF_A3_day6", "TMBPF_A3_day14", "TMBPF_A3_day15", "TMBPF_A3_day13", "TMBPF_A3_day12"]


if __name__ == "__main__":
    # IF YOU WANT TO MERGE TABLES
    # Replace .raw Peak height
    # mzproject.merge_tables.generate_ensemble_list(
    #     r'C:\Users\tinc9\Documents\IJS-offline\tindeResting-IJS\python\Mzinput\tmbpf\\',
    #     samples,
    #     ['A_samples', 'D_samples'],
    #     'pos'
    # )

    # condition A
    if True:
        p_l = {"TMBPF": {"BLANK": ("BLANK.A",), "CONTROL": ("TMBPF.A1.0", "TMBPF.A2.0", "TMBPF.A3.0"),
                         "SAMPLE": ("TMBPF.A1","TMBPF.A2", "TMBPF.A3")}}
        tmbpf_a = master.GenerateList("Mzinput/tmbpf/tmbpf_samples_SampleA_massfeatures_ms2.csv", p_l,
                                   "../data/TMBPF_A_v1")
        tmbpf_a.merged_algorithm('TMBPF')

    # condition D
    if False:
        p_l = {"TMBPF": {"BLANK": ("BLANK.D",), "CONTROL": ("TMBPF.D1.0", "TMBPF.D2.0", "TMBPF.D3.0"),
                         "SAMPLE": ("TMBPF.D1","TMBPF.D2", "TMBPF.D3")}}
        tmbpf_a = master.GenerateList("Mzinput/tmbpf/tmbpf_samples_SampleD_massfeatures_ms2.csv", p_l,
                                   "../data/TMBPF_D_v1")
        tmbpf_a.merged_algorithm('TMBPF')