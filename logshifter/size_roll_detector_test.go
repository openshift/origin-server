package main

import "testing"
import "fmt"

func TestValidStringParsing(t *testing.T) {
	var scenarios = make(map[string]ByteSize)    
	units := [...]string{"B","K","M","G","T","P","E","Z","Y"}
	unitconsts := [...]ByteSize{B,KB,MB,GB,TB,PB,EB,ZB,YB}
	multiples := [...]int{1,10,100}

	c := 0    
	for unit := 0 ; unit<len(units); unit++ {
		for _,multiple := range multiples {    		
			scenarios[fmt.Sprintf("%d%s",c*multiple,units[unit])] = ByteSize(float64(c*multiple) * float64(unitconsts[unit]))    		
			c++
			if c > 9 { 
			  c=0
			}    		
		}
	}
	      
	for str, val := range scenarios {
		bs, err := ParseByteSize([]byte(str))
		if err != nil {
			t.Fatal(err)
		}

		if bs != val {
			t.Fatalf("scenario: %s expected bs=%.0f, got %.0f", str, bs, val)
		}
	}
}
