/******************************************************************************

                              Online C++ Compiler.
               Code, Compile, Run and Debug C++ program online.
Write your code in this editor and press "Run" button to compile and execute it.

*******************************************************************************/

#include <iostream>
using namespace std;

int main()
{
    int n;
    char grade;
    float total = 0;
    
    cout << "จำนวนของนักเรียน: ";  
    cin >> n;
   
    for (int i = 0; i < n; i++) {
        cout << "เกรดของนักเรียนคนที่:" << i + 1 <<":";
        cin >> grade;
        switch (toupper(grade)) {
            case 'A': total += 4.0; break;
            case 'B': total += 3.0; break;
            case 'C': total += 2.0; break;
            case 'D': total += 1.0; break;
            case 'F': total += 0.0; break;
            default:
                cout << "เกรดไม่ถูกต้อง! นับเป็น 0 คะแนน" << endl;
                total += 0.0;
        }
    }
    float average = total / n;
    cout << "ค่าเฉลี่ยเกรดของนักเรียนคือ: " << average << endl;

    return 0;
}
    
    
