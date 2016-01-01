require 'ruby-progressbar'

module Lypack
  PROGRESS_FORMAT = '%t:%B:%p%%'
  
  # Simple wrapper around ProgressBar
  def self.show_progress(title, total)
    $progress_bar = ProgressBar.create(
      title: title,
      total: total,
      format: PROGRESS_FORMAT,
    )
    yield $progress_bar
  ensure
    $progress_bar.stop
    $progress_bar = nil
  end
end