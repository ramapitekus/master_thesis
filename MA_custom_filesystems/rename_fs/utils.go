package main

import (
	"fmt"
	"math"
	"os"
	"strconv"
)

func isMalicious() bool {
	classifier, err := os.ReadFile("../logs/classifier.log")
	if err != nil {
		fmt.Println(err)
	}
	classifierBool, _ := strconv.ParseBool(string(classifier))
	return classifierBool
}


// This is a Go re-implementation of entropy calculation from the following page: 
// https://cocomelonc.github.io/malware/2022/11/05/malware-analysis-6.html
func GetEntropy(data []byte) (entr float64) {
	possible := make(map[string]int)

	for i := 1; i <= 256; i++ {
		possible[string(i)] = 0
	}

	for _, byt := range data {
		possible[string(byt)] += 1
	}

	var data_len = len(data)
	var entropy = 0.0

	for char := range possible {
		if possible[char] == 0 {
			continue
		}
		var p = float64(possible[char]) / float64(data_len)
		entropy -= p * math.Log2(p)
	}
	return entropy
}
