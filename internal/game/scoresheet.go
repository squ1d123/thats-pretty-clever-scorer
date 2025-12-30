package game

type ScoreSheet struct {
	Yellow *YellowScoreArea
	Green  *GreenScoreArea
	Orange *OrangeScoreArea
	Purple *PurpleScoreArea
	Blue   *BlueScoreArea
	Bonus  *BonusArea
}

type YellowScoreArea struct {
	Columns [6][]bool // 6 columns, each with numbers 1-6
	Total   int       // Total score for yellow area
}

type GreenScoreArea struct {
	Numbers []bool // 11 numbers: 2,3,4,5,6,7,8,9,10,11,12
	Total   int    // Total score for green area
}

type OrangeScoreArea struct {
	Numbers []int // 11 spaces for any numbers
	Total   int   // Total score for orange area
}

type PurpleScoreArea struct {
	Numbers []bool // 11 numbers: 1-11, with special 6 reset
	Total   int    // Total score for purple area
}

type BlueScoreArea struct {
	Numbers []bool // 11 numbers: 1-11
	Total   int    // Total score for blue area
}

type BonusArea struct {
	FoxCount int
	Bonus    int // Calculated as lowest_section_score * FoxCount
}

func NewScoreSheet() *ScoreSheet {
	return &ScoreSheet{
		Yellow: &YellowScoreArea{
			Columns: [6][]bool{
				make([]bool, 6), // Column 1: numbers 1-6
				make([]bool, 6), // Column 2: numbers 1-6
				make([]bool, 6), // Column 3: numbers 1-6
				make([]bool, 6), // Column 4: numbers 1-6
				make([]bool, 6), // Column 5: numbers 1-6
				make([]bool, 6), // Column 6: numbers 1-6
			},
		},
		Green: &GreenScoreArea{
			Numbers: make([]bool, 11),
		},
		Orange: &OrangeScoreArea{
			Numbers: make([]int, 11),
		},
		Purple: &PurpleScoreArea{
			Numbers: make([]bool, 11),
		},
		Blue: &BlueScoreArea{
			Numbers: make([]bool, 11),
		},
		Bonus: &BonusArea{
			FoxCount: 0,
			Bonus:    0,
		},
	}
}

func (ss *ScoreSheet) GetTotalScore() int {
	return ss.Yellow.Total + ss.Green.Total + ss.Orange.Total + ss.Purple.Total + ss.Blue.Total + ss.Bonus.Bonus
}

func (ss *ScoreSheet) CalculateBonus() {
	// Calculate bonus as lowest section score * fox count
	sections := []int{ss.Yellow.Total, ss.Green.Total, ss.Orange.Total, ss.Purple.Total, ss.Blue.Total}

	// Find lowest non-zero section
	lowest := 0
	for _, section := range sections {
		if section > 0 && (lowest == 0 || section < lowest) {
			lowest = section
		}
	}

	ss.Bonus.Bonus = lowest * ss.Bonus.FoxCount
}

func calculateYellowScore(yellow *YellowScoreArea) int {
	score := 0
	for col := 0; col < 6; col++ {
		columnComplete := true
		for row := 0; row < 6; row++ {
			if !yellow.Columns[col][row] {
				columnComplete = false
				break
			}
		}
		if columnComplete {
			score += (col + 1) * (col + 1)
		}
	}
	return score
}

func calculateGreenScore(green *GreenScoreArea) int {
	score := 0
	consecutiveCount := 0

	for i := 0; i < len(green.Numbers); i++ {
		if green.Numbers[i] {
			consecutiveCount++
		} else {
			if consecutiveCount > 0 {
				score += consecutiveCount * consecutiveCount
			}
			consecutiveCount = 0
		}
	}

	if consecutiveCount > 0 {
		score += consecutiveCount * consecutiveCount
	}

	return score
}

func calculateOrangeScore(orange *OrangeScoreArea) int {
	score := 0
	for _, num := range orange.Numbers {
		if num > 0 {
			score += num
		}
	}
	return score
}

func calculatePurpleScore(purple *PurpleScoreArea) int {
	score := 0
	for i, marked := range purple.Numbers {
		if marked {
			if i < 5 { // Numbers 1-5
				score += i + 1
			} else if i == 5 { // Number 6
				score += 6
			} else { // Numbers 7-11
				score += i + 1
			}
		}
	}
	return score
}

func calculateBlueScore(blue *BlueScoreArea) int {
	score := 0
	markedCount := 0

	for _, marked := range blue.Numbers {
		if marked {
			markedCount++
		}
	}

	switch markedCount {
	case 1:
		score = 1
	case 2:
		score = 3
	case 3:
		score = 6
	case 4:
		score = 10
	case 5:
		score = 15
	case 6:
		score = 21
	case 7:
		score = 28
	case 8:
		score = 36
	case 9:
		score = 45
	case 10:
		score = 55
	case 11:
		score = 66
	}

	return score
}

func calculateBonusScore(bonus *BonusArea) int {
	return bonus.Bonus
}
