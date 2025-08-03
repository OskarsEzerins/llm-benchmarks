import React from 'react'
import { Card, CardContent, CardHeader, CardTitle } from './ui/card'
import { Alert, AlertTitle, AlertDescription } from './ui/alert'
import { Calculator, AlertTriangle } from 'lucide-react'

export const ScoringExplanation: React.FC = () => {
  return (
    <div className="w-full max-w-none">
      <Card className="border-4 border-black dark:border-white bg-white dark:bg-gray-900 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] dark:shadow-[8px_8px_0px_0px_rgba(255,255,255,1)] hover:translate-x-1 hover:translate-y-1 hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:hover:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] transition-all duration-200">
        <CardHeader className="bg-black dark:bg-white text-white dark:text-black border-b-4 border-black dark:border-white p-4">
          <div className="flex items-center justify-center gap-3">
            <div className="bg-white dark:bg-black text-black dark:text-white w-8 h-8 border-4 border-white dark:border-black flex items-center justify-center shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] dark:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
              <Calculator className="h-4 w-4" />
            </div>
            <CardTitle className="text-xl font-black uppercase tracking-wider text-center">
              How Scoring Works
            </CardTitle>
          </div>
        </CardHeader>
        <CardContent className="p-4 space-y-4 bg-white dark:bg-gray-900">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div className="bg-green-400 dark:bg-green-600 border-4 border-black dark:border-white p-4 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] hover:translate-x-1 hover:translate-y-1 hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] dark:hover:shadow-[2px_2px_0px_0px_rgba(255,255,255,1)] transition-all duration-200">
              <div className="flex items-center gap-3 mb-3">
                <div className="bg-black dark:bg-white text-white dark:text-black w-12 h-12 border-4 border-black dark:border-white flex items-center justify-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] font-black">
                  <span className="text-sm font-black">90%</span>
                </div>
                <h4 className="text-lg font-black uppercase tracking-wider text-black dark:text-white">
                  Test Success Rate
                </h4>
              </div>
              <p className="text-black dark:text-white font-bold text-sm leading-relaxed">
                Percentage of test cases that pass. This measures whether the AI-generated code actually works correctly.
              </p>
            </div>

            <div className="bg-blue-400 dark:bg-blue-600 border-4 border-black dark:border-white p-4 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] hover:translate-x-1 hover:translate-y-1 hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] dark:hover:shadow-[2px_2px_0px_0px_rgba(255,255,255,1)] transition-all duration-200">
              <div className="flex items-center gap-3 mb-3">
                <div className="bg-black dark:bg-white text-white dark:text-black w-12 h-12 border-4 border-black dark:border-white flex items-center justify-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] font-black">
                  <span className="text-sm font-black">10%</span>
                </div>
                <h4 className="text-lg font-black uppercase tracking-wider text-black dark:text-white">
                  Code Quality
                </h4>
              </div>
              <p className="text-black dark:text-white font-bold text-sm leading-relaxed">
                Based on RuboCop static analysis. Quality score decreases linearly from 100 to 0 as offenses increase from 0 to 50.
              </p>
            </div>
          </div>

          <Alert variant="default" className="bg-yellow-400 dark:bg-yellow-500 border-4 border-black dark:border-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] p-3 hover:translate-x-1 hover:translate-y-1 hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] dark:hover:shadow-[2px_2px_0px_0px_rgba(255,255,255,1)] transition-all duration-200">
            <AlertTriangle className="h-5 w-5 text-black dark:text-white mt-1 flex-shrink-0" />
            <AlertDescription className="text-black dark:text-white font-bold text-sm leading-relaxed">
              RuboCop uses strict default settings and may not reflect real-world code quality preferences.
              The quality score should be interpreted as adherence to Ruby style guidelines rather than overall code quality.
            </AlertDescription>
          </Alert>

          <div className="bg-purple-400 dark:bg-purple-600 border-4 border-black dark:border-white p-4 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] hover:translate-x-1 hover:translate-y-1 hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] dark:hover:shadow-[2px_2px_0px_0px_rgba(255,255,255,1)] transition-all duration-200">
            <div className="text-center space-y-3">
              <div className="flex items-center justify-center gap-3 mb-3">
                <div className="bg-black dark:bg-white text-white dark:text-black w-8 h-8 border-4 border-black dark:border-white flex items-center justify-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)]">
                  📐
                </div>
                <h3 className="text-black dark:text-white font-black text-lg uppercase tracking-wider">
                  Calculation Formula
                </h3>
              </div>
              <div className="space-y-2">
                <div className="bg-black dark:bg-white text-white dark:text-black p-3 border-4 border-black dark:border-white font-bold text-sm shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)]">
                  <strong>Score =</strong> (Test Success Rate × 90%) + (Quality Score × 10%)
                </div>
                <div className="bg-black dark:bg-white text-white dark:text-black p-3 border-4 border-black dark:border-white font-bold text-sm shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)]">
                  <strong>Quality =</strong> 100 - ((RuboCop Offenses ÷ 50) × 100), capped 0-100
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
