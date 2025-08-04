import { Card, CardContent } from './ui/card'

export const CallToActionSection = () => (
  <section className="text-center py-8">
    <Card className="max-w-2xl mx-auto border-0 shadow-lg bg-gradient-to-r from-slate-50 to-slate-100 dark:from-slate-800 dark:to-slate-900">
      <CardContent className="pt-8">
        <h3 className="text-2xl font-bold text-foreground mb-4">
          Explore More Benchmarks
        </h3>
        <p className="text-muted-foreground mb-6">
          See how models perform across different programming challenges and complexity levels.
        </p>
      </CardContent>
    </Card>
  </section>
)
