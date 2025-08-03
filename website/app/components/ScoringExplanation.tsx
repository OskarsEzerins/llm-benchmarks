import React from 'react'
import { Card, CardContent, CardHeader, CardTitle } from './ui/card'
import { Alert, AlertTitle, AlertDescription } from './ui/alert'
import { Calculator, AlertTriangle } from 'lucide-react'

export const ScoringExplanation: React.FC = () => {
  return (
    <div className="w-full max-w-none">
      <Card className="border-4 border-black dark:border-white bg-blue-200 dark:bg-blue-900 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] dark:shadow-[8px_8px_0px_0px_rgba(255,255,255,1)] hover:translate-x-1 hover:translate-y-1 hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:hover:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] transition-all duration-200">
        <CardHeader className="bg-black dark:bg-white text-white dark:text-black border-b-4 border-black dark:border-white p-6">
          <div className="flex items-center justify-center gap-4">
            <Calculator className="h-8 w-8" />
            <CardTitle className="text-3xl font-black uppercase tracking-wider text-center">
              📊 How Scoring Works
            </CardTitle>
          </div>
        </CardHeader>
        <CardContent className="p-8 space-y-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <div className="bg-emerald-300 dark:bg-emerald-700 border-4 border-black dark:border-white p-6 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] hover:translate-x-1 hover:translate-y-1 hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] dark:hover:shadow-[2px_2px_0px_0px_rgba(255,255,255,1)] transition-all duration-200">
              <div className="flex items-center gap-4 mb-4">
                <div className="bg-black dark:bg-white text-white dark:text-black w-16 h-16 border-4 border-black dark:border-white flex items-center justify-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)]">
                  <span className="text-xl font-black">90%</span>
                </div>
                <h4 className="text-xl font-black uppercase tracking-wider text-black dark:text-white">
                  Test Success Rate
                </h4>
              </div>
              <p className="text-black dark:text-white font-bold text-base">
                Percentage of test cases that pass. This measures whether the AI-generated code actually works correctly.
              </p>
            </div>

            <div className="bg-blue-300 dark:bg-blue-700 border-4 border-black dark:border-white p-6 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] hover:translate-x-1 hover:translate-y-1 hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] dark:hover:shadow-[2px_2px_0px_0px_rgba(255,255,255,1)] transition-all duration-200">
              <div className="flex items-center gap-4 mb-4">
                <div className="bg-black dark:bg-white text-white dark:text-black w-16 h-16 border-4 border-black dark:border-white flex items-center justify-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)]">
                  <span className="text-xl font-black">10%</span>
                </div>
                <h4 className="text-xl font-black uppercase tracking-wider text-black dark:text-white">
                  Code Quality
                </h4>
              </div>
              <p className="text-black dark:text-white font-bold text-base">
                Based on RuboCop static analysis. Quality score decreases linearly from 100 to 0 as offenses increase from 0 to 50.
              </p>
            </div>
          </div>

          <Alert variant="default" className="bg-yellow-300 dark:bg-yellow-600 border-4 border-black dark:border-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] p-6">
            <AlertTriangle className="h-6 w-6 text-black dark:text-white mt-1 flex-shrink-0" />
              <AlertTitle className="text-black dark:text-white font-black uppercase tracking-wider text-lg mb-2">
                ⚠️ Important Note
              </AlertTitle>
              <AlertDescription className="text-black dark:text-white font-bold text-base">
                RuboCop uses strict default settings and may not reflect real-world code quality preferences.
                The quality score should be interpreted as adherence to Ruby style guidelines rather than overall code quality.
              </AlertDescription>
          </Alert>

          <div className="bg-purple-300 dark:bg-purple-700 border-4 border-black dark:border-white p-6 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)]">
            <div className="text-center space-y-4">
              <div className="text-black dark:text-white font-black text-lg uppercase tracking-wider mb-4">
                📐 Calculation Formula
              </div>
              <div className="bg-black dark:bg-white text-white dark:text-black p-4 border-4 border-black dark:border-white font-bold text-base">
                <strong>Score =</strong> (Test Success Rate × 90%) + (Quality Score × 10%)
              </div>
              <div className="bg-black dark:bg-white text-white dark:text-black p-4 border-4 border-black dark:border-white font-bold text-base">
                <strong>Quality =</strong> 100 - ((RuboCop Offenses ÷ 50) × 100), capped 0-100
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
