package scenes.game
{
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	
	import events.NavigationEvent;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import graph.Network;
	
	import scenes.Scene;
	import scenes.game.display.World;
	import scenes.login.LoginHelper;
	
	import starling.core.Starling;
	import starling.display.*;
	import starling.events.Event;
	
	import state.ParseXMLState;
	
	public class PipeJamGameScene extends Scene
	{		
		public var worldFileLoader:URLLoader;
		public var layoutLoader:URLLoader;
		public var constraintsLoader:URLLoader;
		protected var nextParseState:ParseXMLState;
		
		static public var demoButtonWorldFile:String = "../SampleWorlds/Simple.zip";
		static public var demoButtonLayoutFile:String = "../SampleWorlds/SimpleLayout.zip";
		static public var demoButtonConstraintsFile:String = "../SampleWorlds/SimpleConstraints.zip";
		
		static public var dArray:Array = new Array(
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_CollectGcBiasMetrics.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_CollectGcBiasMetricsConstraints.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_CollectGcBiasMetricsLayout.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_CollectInsertSizeMetrics.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_CollectInsertSizeMetricsConstraints.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_CollectInsertSizeMetricsLayout.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_CollectRnaSeqMetrics.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_CollectRnaSeqMetricsConstraints.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_CollectRnaSeqMetricsLayout.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_directed_CollectTargetedMetrics.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_directed_CollectTargetedMetricsConstraints.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_directed_CollectTargetedMetricsLayout.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_directed_InsertSizeMetricsCollector_PerUnitInsertSizeMetricsCollector.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_directed_InsertSizeMetricsCollector_PerUnitInsertSizeMetricsCollectorConstraints.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_directed_InsertSizeMetricsCollector_PerUnitInsertSizeMetricsCollectorLayout.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_directed_RnaSeqMetricsCollector_PerUnitRnaSeqMetricsCollector.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_directed_RnaSeqMetricsCollector_PerUnitRnaSeqMetricsCollectorConstraints.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_directed_RnaSeqMetricsCollector_PerUnitRnaSeqMetricsCollectorLayout.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_SinglePassSamProgram.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_SinglePassSamProgramConstraints.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_analysis_SinglePassSamProgramLayout.zip",
////			"C:\\AltogetherLayers\\net_sf_picard_annotation_RefFlatReader.zip",
////			"C:\\AltogetherLayers\\net_sf_picard_annotation_RefFlatReaderConstraints.zip",
////			"C:\\AltogetherLayers\\net_sf_picard_annotation_RefFlatReaderLayout.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParser.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParserConstraints.zip",
//			"C:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParserLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParser_OptionDefinition.zip",
			"C:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParser_OptionDefinitionConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParser_OptionDefinitionLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineProgram.zip",
			"C:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineProgramConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineProgramLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_fastq_BamToBfq.zip",
			"C:\\AltogetherLayers\\net_sf_picard_fastq_BamToBfqConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_fastq_BamToBfqLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_fastq_BamToBfqWriter.zip",
			"C:\\AltogetherLayers\\net_sf_picard_fastq_BamToBfqWriterConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_fastq_BamToBfqWriterLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_fastq_FastqReader.zip",
			"C:\\AltogetherLayers\\net_sf_picard_fastq_FastqReaderConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_fastq_FastqReaderLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_fastq_FastqRecord.zip",
			"C:\\AltogetherLayers\\net_sf_picard_fastq_FastqRecordConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_fastq_FastqRecordLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MetricBase.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MetricBaseConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MetricBaseLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MetricsFile.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MetricsFileConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MetricsFileLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollectorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollectorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_AllReadsDistributor.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_AllReadsDistributorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_AllReadsDistributorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MultilevelMetrics.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MultilevelMetricsConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_MultilevelMetricsLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_StringHeader.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_StringHeaderConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_StringHeaderLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_VersionHeader.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_VersionHeaderConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_metrics_VersionHeaderLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_AbstractFastaSequenceFile.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_AbstractFastaSequenceFileConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_AbstractFastaSequenceFileLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceFile.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceFileConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceFileLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceIndexEntry.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceIndexEntryConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceIndexEntryLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceIndex.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceIndexConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceIndexLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_IndexedFastaSequenceFile.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_IndexedFastaSequenceFileConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_IndexedFastaSequenceFileLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_NormalizeFasta.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_NormalizeFastaConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_NormalizeFastaLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceFileWalker.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceFileWalkerConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceFileWalkerLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_AbstractAlignmentMerger.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_AbstractAlignmentMergerConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_AbstractAlignmentMergerLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_AbstractDuplicateFindingAlgorithm.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_AbstractDuplicateFindingAlgorithmConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_AbstractDuplicateFindingAlgorithmLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_AddOrReplaceReadGroups.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_AddOrReplaceReadGroupsConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_AddOrReplaceReadGroupsLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_BuildBamIndex.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_BuildBamIndexConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_BuildBamIndexLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_ComparableSamRecordIterator.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_ComparableSamRecordIteratorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_ComparableSamRecordIteratorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_CompareSAMs.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_CompareSAMsConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_CompareSAMsLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMap.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMapConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMapLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMap_MapIterator.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMap_MapIteratorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMap_MapIteratorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_CreateSequenceDictionary.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_CreateSequenceDictionaryConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_CreateSequenceDictionaryLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_DownsampleSam.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_DownsampleSamConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_DownsampleSamLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_DuplicationMetrics.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_DuplicationMetricsConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_DuplicationMetricsLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexityConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexityLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity_PairedReadCodec.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity_PairedReadCodecConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity_PairedReadCodecLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_FastqToSam.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_FastqToSamConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_FastqToSamLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_FilterSamReads.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_FilterSamReadsConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_FilterSamReadsLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicates.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicatesConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicatesLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MergeBamAlignment.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MergeBamAlignmentConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MergeBamAlignmentLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MergeSamFiles.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MergeSamFilesConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MergeSamFilesLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIteratorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIteratorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_HitsForInsert.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_HitsForInsertConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_HitsForInsertLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_RAMReadEndsMap.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_RAMReadEndsMapConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_RAMReadEndsMapLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_ReadEndsCodec.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_ReadEndsCodecConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_ReadEndsCodecLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_ReorderSam.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_ReorderSamConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_ReorderSamLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_SamToFastq.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_SamToFastqConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_SamToFastqLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_ValidateSamFile.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_ValidateSamFileConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_sam_ValidateSamFileLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_Histogram.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_HistogramConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_HistogramLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_Histogram_Bin.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_Histogram_BinConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_Histogram_BinLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IlluminaUtil.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IlluminaUtilConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IlluminaUtilLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_Interval.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalList.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalListConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalListLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalListTools.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalListToolsConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalListToolsLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMapConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMapLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_EntryIterator.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_EntryIteratorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_EntryIteratorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_EntrySet.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_EntrySetConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_EntrySetLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_Log.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_LogConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_LogLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_MathUtil.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_MathUtilConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_MathUtilLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_MetricsDoclet.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_MetricsDocletConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_MetricsDocletLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_ProcessOutputReader.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_ProcessOutputReaderConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_ProcessOutputReaderLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_ProgressLogger.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_ProgressLoggerConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_ProgressLoggerLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetectorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetectorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_-1.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_-1Constraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_-1Layout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_QualityUtil.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_QualityUtilConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_QualityUtilLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_RExecutor.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_RExecutorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_RExecutorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_SamLocusIterator.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_SamLocusIteratorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_SamLocusIteratorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIteratorFactory_StopAfterFilteringIterator.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIteratorFactory_StopAfterFilteringIteratorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIteratorFactory_StopAfterFilteringIteratorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIterator.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIteratorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIteratorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_SolexaQualityConverter.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_SolexaQualityConverterConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_SolexaQualityConverterLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParser.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParserConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParserLayout.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParser_Row.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParser_RowConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParser_RowLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndexConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndexLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_MemoryMappedFileBuffer.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_MemoryMappedFileBufferConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_MemoryMappedFileBufferLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_RandomAccessFileBuffer.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_RandomAccessFileBufferConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_RandomAccessFileBufferLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_AbstractSAMHeaderRecord.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_AbstractSAMHeaderRecordConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_AbstractSAMHeaderRecordLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BAMFileSpan.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BAMFileSpanConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BAMFileSpanLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BAMFileWriter.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BAMFileWriterConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BAMFileWriterLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BAMIndexContent_BinList.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BAMIndexContent_BinListConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BAMIndexContent_BinListLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BAMIndexer_BAMIndexBuilder.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BAMIndexer_BAMIndexBuilderConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BAMIndexer_BAMIndexBuilderLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BamIndexValidator.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BamIndexValidatorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BamIndexValidatorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BinaryTagCodec.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BinaryTagCodecConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BinaryTagCodecLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_Bin.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BinConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_BinLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_CachingBAMFileIndex.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_CachingBAMFileIndexConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_CachingBAMFileIndexLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_Chunk.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_ChunkConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_ChunkLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_CigarElement.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_CigarElementConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_CigarElementLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_Cigar.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_CigarConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_CigarLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_DiskBasedBAMFileIndex.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_DiskBasedBAMFileIndexConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_DiskBasedBAMFileIndexLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMBinaryTagAndValue.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMBinaryTagAndValueConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMBinaryTagAndValueLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMFileHeader.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMFileHeaderConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMFileHeaderLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMFileHeader_SortOrder.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMFileHeader_SortOrderConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMFileHeader_SortOrderLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMFileSource.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMFileSourceConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMFileSourceLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMFileWriterImpl.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMFileWriterImplConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMFileWriterImplLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMProgramRecord.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMProgramRecordConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMProgramRecordLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMReadGroupRecord.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMReadGroupRecordConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMReadGroupRecordLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMRecord.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMRecordConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMRecordLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMRecordSetBuilder.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMRecordSetBuilderConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMRecordSetBuilderLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMSequenceRecord.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMSequenceRecordConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMSequenceRecordLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMSortOrderChecker.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMSortOrderCheckerConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMSortOrderCheckerLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMTextWriter.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMTextWriterConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMTextWriterLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMTools.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMToolsConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMToolsLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMValidationError.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMValidationErrorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMValidationErrorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMValidationError_Type.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMValidationError_TypeConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_SAMValidationError_TypeLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_TextTagCodec.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_TextTagCodecConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_TextTagCodecLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_AbstractAsyncWriter.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_AbstractAsyncWriterConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_AbstractAsyncWriterLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedInputStream.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedInputStreamConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedInputStreamLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedOutputStream.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedOutputStreamConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedOutputStreamLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_BufferedLineReader.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_BufferedLineReaderConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_BufferedLineReaderLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_DateParser.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_DateParserConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_DateParserLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_HttpUtils.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_HttpUtilsConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_HttpUtilsLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_IOUtil.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_IOUtilConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_IOUtilLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_Md5CalculatingInputStream.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_Md5CalculatingInputStreamConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_Md5CalculatingInputStreamLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_Md5CalculatingOutputStream.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_Md5CalculatingOutputStreamConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_Md5CalculatingOutputStreamLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_RuntimeIOException.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_RuntimeIOExceptionConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_RuntimeIOExceptionLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SeekableHTTPStream.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SeekableHTTPStreamConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SeekableHTTPStreamLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SequenceUtil.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SequenceUtilConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SequenceUtilLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SnappyLoader.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SnappyLoaderConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SnappyLoaderLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SortingCollectionConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SortingCollectionLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollectionConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollectionLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection_PeekFileValueIterator.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection_PeekFileValueIteratorConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection_PeekFileValueIteratorLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_StringLineReader.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_StringLineReaderConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_StringLineReaderLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_StringUtil.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_StringUtilConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_StringUtilLayout.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_TempStreamFactory.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_TempStreamFactoryConstraints.zip",
			"C:\\AltogetherLayers\\net_sf_samtools_util_TempStreamFactoryLayout.zip"

);
		
		static public var tutorialButtonWorldFile:String = "../SampleWorlds/DemoWorld/tutorial.zip";
		static public var tutorialButtonLayoutFile:String = "../SampleWorlds/DemoWorld/tutorialLayout.zip";
		static public var tutorialButtonConstraintsFile:String = "../SampleWorlds/DemoWorld/tutorialConstraints.zip";
		
		static public var worldFile:String = demoButtonWorldFile;
		static public var layoutFile:String = demoButtonLayoutFile;
		static public var constraintsFile:String = demoButtonConstraintsFile;
		private var world_zip_file_to_be_played:String;// = "../SampleWorlds/DemoWorld.zip";
		public var m_worldXML:XML;
		public var m_worldLayout:XML;
		public var m_worldConstraints:XML;
		private var fz1:FZip;
		private var fz2:FZip;
		private var fz3:FZip;
		
		protected var m_layoutLoaded:Boolean = false;
		protected var m_constraintsLoaded:Boolean = false;
		protected var m_worldLoaded:Boolean = false;

		/** Start button image */
		protected var start_button:Button;
		private var active_world:World;
		private var m_network:Network;
		
		public function PipeJamGameScene(game:PipeJamGame)
		{
			super(game);
		}
		
		protected override function addedToStage(event:starling.events.Event):void
		{
			var loginHelper:LoginHelper = LoginHelper.getLoginHelper();
			super.addedToStage(event);
			dispatchEvent(new starling.events.Event(Game.START_BUSY_ANIMATION,true));

			if (!world_zip_file_to_be_played)
			{
				var loadType:int = LoginHelper.USE_LOCAL;
				
				var obj:Object = Starling.current.nativeStage.loaderInfo.parameters;
				var fileName:String = obj["files"];
				if(LoginHelper.levelObject != null) //load from MongoDB
				{
					loadType = LoginHelper.USE_DATABASE;
					worldFile = "/level/get/" + LoginHelper.levelObject.xmlID+"/xml";
					layoutFile = "/level/get/" + LoginHelper.levelObject.layoutID+"/layout";
					constraintsFile = "/level/get/" + LoginHelper.levelObject.constraintsID+"/constraints";		
				}
				else if(fileName && fileName.length > 0)
				{
					worldFile = "../SampleWorlds/DemoWorld/"+fileName+".zip";
					layoutFile = "../SampleWorlds/DemoWorld/"+fileName+"Layout.zip";
					constraintsFile = "../SampleWorlds/DemoWorld/"+fileName+"Constraints.zip";
				}
				
				m_layoutLoaded = m_worldLoaded = m_constraintsLoaded = false;
			
				fz1 = new FZip();
				loginHelper.loadFile(loadType, null, worldFile, worldZipLoaded, fz1);
				fz2 = new FZip();
				loginHelper.loadFile(loadType, null, layoutFile, layoutZipLoaded, fz2);
				fz3 = new FZip();
				loginHelper.loadFile(loadType, null, constraintsFile, constraintsZipLoaded, fz3);
			}
			else
			 {
				//load the zip file from it's location
				loadType = LoginHelper.USE_URL;
				fz1 = new FZip();
				fz1.addEventListener(flash.events.Event.COMPLETE, worldZipLoaded);
				fz1.load(new URLRequest(world_zip_file_to_be_played));
			}
			initGame();

		}
		
		protected  override function removedFromStage(event:starling.events.Event):void
		{
			removeChildren(0, -1, true);
			active_world = null;
		}
		
		
		/**
		 * Run once to initialize the game
		 */
		public function initGame():void 
		{

		}
		
		public function onLayoutLoaded(byteArray:ByteArray):void {
			m_worldLayout = new XML(byteArray); 
			m_layoutLoaded = true;
			//call, but probably wait on xml
			tasksComplete();
		}
		
		public function onConstraintsLoaded(byteArray:ByteArray):void {
			m_worldConstraints = new XML(byteArray); 
			m_constraintsLoaded = true;
			//call, but probably wait on xml
			tasksComplete();
		}
		
		public function onWorldLoaded(byteArray:ByteArray):void { 
			var worldXML:XML  = new XML(byteArray); 
			m_worldLoaded = true;
			parseXML(worldXML);
		}
		
			
		private function worldZipLoaded(e:flash.events.Event):void {
			fz1.removeEventListener(flash.events.Event.COMPLETE, worldZipLoaded);
			if(fz1.getFileCount() > 0)
			{
				var zipFile:FZipFile = fz1.getFileAt(0);
				trace(zipFile.filename);
				onWorldLoaded(zipFile.content);
			}
			else
				trace("zip failed");
		}
		
		private function layoutZipLoaded(e:flash.events.Event):void {
			fz2.removeEventListener(flash.events.Event.COMPLETE, layoutZipLoaded);
			if(fz2.getFileCount() > 0)
			{
				var zipFile:FZipFile = fz2.getFileAt(0);
				trace(zipFile.filename);
				onLayoutLoaded(zipFile.content);
			}
			else
				trace("zip failed");
		}
		
		private function constraintsZipLoaded(e:flash.events.Event):void {
			fz3.removeEventListener(flash.events.Event.COMPLETE, constraintsZipLoaded);
			if(fz3.getFileCount() > 0)
			{
				var zipFile:FZipFile = fz3.getFileAt(0);
				trace(zipFile.filename);
				onConstraintsLoaded(zipFile.content);
			}
			else
				trace("zip failed");
		}
		
		public function parseXML(world_xml:XML):void
		{
			m_worldXML = world_xml;
			if(nextParseState)
				nextParseState.removeFromParent();
			nextParseState = new ParseXMLState(world_xml);
			addChild(nextParseState); //to allow done parsing event to be caught
			this.addEventListener(ParseXMLState.WORLD_PARSED, worldComplete);
			nextParseState.stateLoad();
		}
		
		public function worldComplete(event:starling.events.Event):void
		{
			m_network = event.data as Network;
			m_worldLoaded = true;
			this.removeEventListener(ParseXMLState.WORLD_PARSED, worldComplete);
			tasksComplete();
		}
		
		public function tasksComplete():void
		{
			if(m_layoutLoaded && m_worldLoaded && m_constraintsLoaded)
			{
				trace("everything loaded");
				if(nextParseState)
					nextParseState.removeFromParent();
				
				active_world = createWorldFromNodes(m_network, m_worldXML, m_worldLayout, m_worldConstraints);		
				
				addChild(active_world);
			}
		}
		
		
		/**
		 * This function is called after the graph structure (Nodes, edges) has been read in from XML. It converts nodes/edges to a playable world.
		 * @param	_worldNodes
		 * @param	_world_xml
		 * @return
		 */
		public function createWorldFromNodes(_worldNodes:Network, _world_xml:XML, _layout:XML, _constraints:XML):World {
			try {
				
				m_network = _worldNodes;
				PipeJamGame.printDebug("Creating World...");
				var world:World = new World(_worldNodes, _world_xml, _layout, _constraints);				
			} catch (error:Error) {
				throw new Error("ERROR: " + error.message + "\n" + (error as Error).getStackTrace());
				var debug:int = 0;
			}
			
			return world;
		}
	}
}