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
		
		static public var demoButtonWorldFile:String = "../SampleWorlds/DemoWorld/Simple.zip";
		static public var demoButtonLayoutFile:String = "../SampleWorlds/SimpleLayout.zip";
		static public var demoButtonConstraintsFile:String = "../SampleWorlds/SimpleConstraints.zip";
		
		static public var dArray:Array = new Array(
			//			"../AltogetherLayers/net_sf_picard_reference_FastaSequenceIndexEntry.zip",
			//			"../AltogetherLayers/net_sf_picard_reference_FastaSequenceIndexEntryConstraints.zip",
			//			"../AltogetherLayers/net_sf_picard_reference_FastaSequenceIndexLayout.zip",
			//						"../AltogetherLayers/net_sf_picard_analysis_AlignmentSummaryMetrics.zip",
			//						"../AltogetherLayers/net_sf_picard_analysis_AlignmentSummaryMetricsConstraints.zip",
			//						"../AltogetherLayers/net_sf_picard_analysis_AlignmentSummaryMetricsLayout.zip",
			//						"../AltogetherLayers/net_sf_picard_analysis_AlignmentSummaryMetrics_Category.zip",
			//						"../AltogetherLayers/net_sf_picard_analysis_AlignmentSummaryMetrics_CategoryConstraints.zip",
			//						"../AltogetherLayers/net_sf_picard_analysis_AlignmentSummaryMetrics_CategoryLayout.zip",
//			"../AltogetherLayers/net_sf_picard_analysis_CollectInsertSizeMetrics.zip",
//			"../AltogetherLayers/net_sf_picard_analysis_CollectInsertSizeMetricsConstraints.zip",
//			"../AltogetherLayers/net_sf_picard_analysis_CollectInsertSizeMetricsLayout.zip",
//			"../AltogetherLayers/net_sf_picard_analysis_CollectGcBiasMetrics.zip",
//			"../AltogetherLayers/net_sf_picard_analysis_CollectGcBiasMetricsConstraints.zip",
//			"../AltogetherLayers/net_sf_picard_analysis_CollectGcBiasMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_CollectRnaSeqMetrics.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_CollectRnaSeqMetricsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_CollectRnaSeqMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_CalculateHsMetrics.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_CalculateHsMetricsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_CalculateHsMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_CollectTargetedMetrics.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_CollectTargetedMetricsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_CollectTargetedMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_CollectTargetedPcrMetrics.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_CollectTargetedPcrMetricsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_CollectTargetedPcrMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_HsMetricCollector.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_HsMetricCollectorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_HsMetricCollectorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_HsMetrics.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_HsMetricsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_HsMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_InsertSizeCollectorArgs.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_InsertSizeCollectorArgsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_InsertSizeCollectorArgsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_InsertSizeMetricsCollector.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_InsertSizeMetricsCollectorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_InsertSizeMetricsCollectorLayout.zip",
//			"../AltogetherLayers/net_sf_picard_analysis_directed_InsertSizeMetricsCollector_PerUnitInsertSizeMetricsCollector.zip",
//			"../AltogetherLayers/net_sf_picard_analysis_directed_InsertSizeMetricsCollector_PerUnitInsertSizeMetricsCollectorConstraints.zip",
//			"../AltogetherLayers/net_sf_picard_analysis_directed_InsertSizeMetricsCollector_PerUnitInsertSizeMetricsCollectorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_RnaSeqMetricsCollector.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_RnaSeqMetricsCollectorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_RnaSeqMetricsCollectorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_RnaSeqMetricsCollector_PerUnitRnaSeqMetricsCollector.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_RnaSeqMetricsCollector_PerUnitRnaSeqMetricsCollectorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_RnaSeqMetricsCollector_PerUnitRnaSeqMetricsCollectorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_RnaSeqMetricsCollector_StrandSpecificity.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_RnaSeqMetricsCollector_StrandSpecificityConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_RnaSeqMetricsCollector_StrandSpecificityLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_TargetedPcrMetrics.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_TargetedPcrMetricsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_TargetedPcrMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_TargetedPcrMetricsCollector.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_TargetedPcrMetricsCollectorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_directed_TargetedPcrMetricsCollectorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_GcBiasDetailMetrics.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_GcBiasDetailMetricsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_GcBiasDetailMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_GcBiasSummaryMetrics.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_GcBiasSummaryMetricsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_GcBiasSummaryMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_InsertSizeMetrics.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_InsertSizeMetricsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_InsertSizeMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_MeanQualityByCycle.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_MeanQualityByCycleConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_MeanQualityByCycleLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_MeanQualityByCycle_HistogramGenerator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_MeanQualityByCycle_HistogramGeneratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_MeanQualityByCycle_HistogramGeneratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_MetricAccumulationLevel.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_MetricAccumulationLevelConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_MetricAccumulationLevelLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_QualityScoreDistribution.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_QualityScoreDistributionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_QualityScoreDistributionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_RnaSeqMetrics.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_RnaSeqMetricsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_RnaSeqMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_SinglePassSamProgram.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_SinglePassSamProgramConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_analysis_SinglePassSamProgramLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_annotation_AnnotationException.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_annotation_AnnotationExceptionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_annotation_AnnotationExceptionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_annotation_GeneAnnotationReader.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_annotation_GeneAnnotationReaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_annotation_GeneAnnotationReaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_annotation_LocusFunction.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_annotation_LocusFunctionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_annotation_LocusFunctionLayout.zip",
//			"../AltogetherLayers//net_sf_picard_annotation_RefFlatReader.zip",
//			"../AltogetherLayers//net_sf_picard_annotation_RefFlatReaderConstraints.zip",
//			"../AltogetherLayers//net_sf_picard_annotation_RefFlatReaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_annotation_RefFlatReader_RefFlatColumns.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_annotation_RefFlatReader_RefFlatColumnsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_annotation_RefFlatReader_RefFlatColumnsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParseException.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParseExceptionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParseExceptionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParser.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParserConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParserLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParserDefinitionException.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParserDefinitionExceptionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineParserDefinitionExceptionLayout.zip",
//			"../AltogetherLayers/net_sf_picard_cmdline_CommandLineParser_OptionDefinition.zip",
//			"../AltogetherLayers/net_sf_picard_cmdline_CommandLineParser_OptionDefinitionConstraints.zip",
//			"../AltogetherLayers/net_sf_picard_cmdline_CommandLineParser_OptionDefinitionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineProgram.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineProgramConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CommandLineProgramLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CreateHtmlDocForProgram.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CreateHtmlDocForProgramConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CreateHtmlDocForProgramLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CreateHtmlDocForStandardOptions.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CreateHtmlDocForStandardOptionsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CreateHtmlDocForStandardOptionsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CreateHtmlDocForStandardOptions_DummyProgram.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CreateHtmlDocForStandardOptions_DummyProgramConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_CreateHtmlDocForStandardOptions_DummyProgramLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_Option.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_OptionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_OptionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_PositionalArguments.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_PositionalArgumentsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_PositionalArgumentsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_StandardOptionDefinitions.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_StandardOptionDefinitionsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_StandardOptionDefinitionsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_Usage.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_UsageConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_cmdline_UsageLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_AsyncFastqWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_AsyncFastqWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_AsyncFastqWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_BamToBfq.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_BamToBfqConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_BamToBfqLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_BamToBfqWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_BamToBfqWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_BamToBfqWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_BasicFastqWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_BasicFastqWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_BasicFastqWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_FastqConstants.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_FastqConstantsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_FastqConstantsLayout.zip",
//			"../AltogetherLayers/net_sf_picard_fastq_FastqReader.zip",
//			"../AltogetherLayers/net_sf_picard_fastq_FastqReaderConstraints.zip",
//			"../AltogetherLayers/net_sf_picard_fastq_FastqReaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_FastqRecord.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_FastqRecordConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_FastqRecordLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_FastqWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_FastqWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_FastqWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_FastqWriterFactory.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_FastqWriterFactoryConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_fastq_FastqWriterFactoryLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_Header.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_HeaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_HeaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MetricBase.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MetricBaseConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MetricBaseLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MetricsFile.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MetricsFileConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MetricsFileLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollectorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollectorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_AllReadsDistributor.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_AllReadsDistributorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_AllReadsDistributorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_Distributor.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_DistributorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_DistributorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_LibraryDistributor.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_LibraryDistributorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_LibraryDistributorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_ReadGroupCollector.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_ReadGroupCollectorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_ReadGroupCollectorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_SampleDistributor.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_SampleDistributorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultiLevelCollector_SampleDistributorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultilevelMetrics.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultilevelMetricsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_MultilevelMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_PerUnitMetricCollector.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_PerUnitMetricCollectorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_PerUnitMetricCollectorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_SAMRecordAndReference.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_SAMRecordAndReferenceConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_SAMRecordAndReferenceLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_SAMRecordAndReferenceMultiLevelCollector.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_SAMRecordAndReferenceMultiLevelCollectorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_SAMRecordAndReferenceMultiLevelCollectorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_SAMRecordMultiLevelCollector.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_SAMRecordMultiLevelCollectorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_SAMRecordMultiLevelCollectorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_StringHeader.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_StringHeaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_metrics_StringHeaderLayout.zip",
			"../AltogetherLayers/net_sf_picard_metrics_VersionHeader.zip",
			"../AltogetherLayers/net_sf_picard_metrics_VersionHeaderConstraints.zip",
			"../AltogetherLayers/net_sf_picard_metrics_VersionHeaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_AbstractFastaSequenceFile.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_AbstractFastaSequenceFileConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_AbstractFastaSequenceFileLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ExtractSequences.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ExtractSequencesConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ExtractSequencesLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceFile.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceFileConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceFileLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceIndex.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceIndexConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_FastaSequenceIndexEntryLayout.zip",
			
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_IndexedFastaSequenceFile.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_IndexedFastaSequenceFileConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_IndexedFastaSequenceFileLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_NormalizeFasta.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_NormalizeFastaConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_NormalizeFastaLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequence.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceFile.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceFileConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceFileLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceFileFactory.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceFileFactoryConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceFileFactoryLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceFileWalker.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceFileWalkerConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_reference_ReferenceSequenceFileWalkerLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractAlignmentMerger.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractAlignmentMergerConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractAlignmentMergerLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractAlignmentMerger_-1.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractAlignmentMerger_-1Constraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractAlignmentMerger_-1Layout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractDuplicateFindingAlgorithm.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractDuplicateFindingAlgorithmConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractDuplicateFindingAlgorithmLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractDuplicateFindingAlgorithm_-1.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractDuplicateFindingAlgorithm_-1Constraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractDuplicateFindingAlgorithm_-1Layout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractDuplicateFindingAlgorithm_PhysicalLocation.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractDuplicateFindingAlgorithm_PhysicalLocationConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AbstractDuplicateFindingAlgorithm_PhysicalLocationLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AddOrReplaceReadGroups.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AddOrReplaceReadGroupsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_AddOrReplaceReadGroupsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_BamIndexStats.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_BamIndexStatsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_BamIndexStatsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_BestMapqPrimaryAlignmentSelectionStrategy.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_BestMapqPrimaryAlignmentSelectionStrategyConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_BestMapqPrimaryAlignmentSelectionStrategyLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_BuildBamIndex.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_BuildBamIndexConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_BuildBamIndexLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CleanSam.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CleanSamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CleanSamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ComparableSamRecordIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ComparableSamRecordIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ComparableSamRecordIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CompareSAMs.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CompareSAMsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CompareSAMsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMap.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMapConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMapLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMap_Codec.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMap_CodecConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMap_CodecLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMap_MapIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMap_MapIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CoordinateSortedPairInfoMap_MapIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CreateSequenceDictionary.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CreateSequenceDictionaryConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_CreateSequenceDictionaryLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_DiskReadEndsMap.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_DiskReadEndsMapConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_DiskReadEndsMapLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_DiskReadEndsMap_Codec.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_DiskReadEndsMap_CodecConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_DiskReadEndsMap_CodecLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_DownsampleSam.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_DownsampleSamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_DownsampleSamLayout.zip",
			//			//100
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_DuplicationMetrics.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_DuplicationMetricsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_DuplicationMetricsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EarliestFragmentPrimaryAlignmentSelectionStrategy.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EarliestFragmentPrimaryAlignmentSelectionStrategyConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EarliestFragmentPrimaryAlignmentSelectionStrategyLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexityConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexityLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity_PairedReadCodec.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity_PairedReadCodecConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity_PairedReadCodecLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity_PairedReadComparator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity_PairedReadComparatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity_PairedReadComparatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity_PairedReadSequence.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity_PairedReadSequenceConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_EstimateLibraryComplexity_PairedReadSequenceLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_FastqToSam.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_FastqToSamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_FastqToSamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_FilterSamReads.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_FilterSamReadsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_FilterSamReadsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_FilterSamReads_Filter.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_FilterSamReads_FilterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_FilterSamReads_FilterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicates.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicatesConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicatesLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicates_PgIdGenerator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicates_PgIdGeneratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicates_PgIdGeneratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicates_ReadEndsComparator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicates_ReadEndsComparatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicates_ReadEndsComparatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicates_SamHeaderAndIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicates_SamHeaderAndIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MarkDuplicates_SamHeaderAndIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MergeBamAlignment.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MergeBamAlignmentConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MergeBamAlignmentLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MergeBamAlignment_PrimaryAlignmentStrategy.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MergeBamAlignment_PrimaryAlignmentStrategyConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MergeBamAlignment_PrimaryAlignmentStrategyLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MergeSamFiles.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MergeSamFilesConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MergeSamFilesLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_-1.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_-1Constraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_-1Layout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_HitIndexComparator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_HitIndexComparatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_HitIndexComparatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_HitsForInsert.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_HitsForInsertConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_HitsForInsertLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_NumPrimaryAlignmentState.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_NumPrimaryAlignmentStateConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_MultiHitAlignedReadIterator_NumPrimaryAlignmentStateLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_PrimaryAlignmentSelectionStrategy.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_PrimaryAlignmentSelectionStrategyConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_PrimaryAlignmentSelectionStrategyLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_RAMReadEndsMap.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_RAMReadEndsMapConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_RAMReadEndsMapLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReadEndsCodec.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReadEndsCodecConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReadEndsCodecLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReadEndsMap.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReadEndsMapConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReadEndsMapLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReorderSam.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReorderSamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReorderSamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReplaceSamHeader.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReplaceSamHeaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReplaceSamHeaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReservedTagConstants.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReservedTagConstantsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ReservedTagConstantsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_SamFormatConverter.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_SamFormatConverterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_SamFormatConverterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_SamToFastq.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_SamToFastqConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_SamToFastqLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_SortSam.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_SortSamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_SortSamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ValidateSamFile.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ValidateSamFileConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ValidateSamFileLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ValidateSamFile_Mode.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ValidateSamFile_ModeConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ValidateSamFile_ModeLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ViewSam.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ViewSamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ViewSamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ViewSam_AlignmentStatus.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ViewSam_AlignmentStatusConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ViewSam_AlignmentStatusLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ViewSam_PfStatus.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ViewSam_PfStatusConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_sam_ViewSam_PfStatusLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_Histogram.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_HistogramConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_HistogramLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_Histogram_Bin.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_Histogram_BinConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_Histogram_BinLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IlluminaUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IlluminaUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IlluminaUtilLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IlluminaUtil_IlluminaAdapterPair.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IlluminaUtil_IlluminaAdapterPairConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IlluminaUtil_IlluminaAdapterPairLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_Interval.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalCoordinateComparator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalCoordinateComparatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalCoordinateComparatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalList.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalListConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalListLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalListReferenceSequenceMask.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalListReferenceSequenceMaskConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalListReferenceSequenceMaskLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalListTools.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalListToolsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalListToolsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMapConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMapLayout.zip",
			//			
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_EntryIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_EntryIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_EntryIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_EntrySet.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_EntrySetConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_EntrySetLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_MapEntry.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_MapEntryConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalTreeMap_MapEntryLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_IntervalUtilLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_Locus.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_LocusComparator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_LocusComparatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_LocusComparatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_LocusConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_LocusImpl.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_LocusImplConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_LocusImplLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_LocusLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_Log.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_LogConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_LogLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_Log_LogLevel.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_Log_LogLevelConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_Log_LogLevelLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_MathUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_MathUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_MathUtilLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_MetricsDoclet.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_MetricsDocletConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_MetricsDocletLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_PeekableIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_PeekableIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_PeekableIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_-1.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_-1Constraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_-1Layout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_LogErrorProcessOutputReader.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_LogErrorProcessOutputReaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_LogErrorProcessOutputReaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_LogInfoProcessOutputReader.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_LogInfoProcessOutputReaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_LogInfoProcessOutputReaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_ProcessOutputReader.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_ProcessOutputReaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_ProcessOutputReaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_StringBuilderProcessOutputReader.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_StringBuilderProcessOutputReaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProcessExecutor_StringBuilderProcessOutputReaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProgressLogger.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProgressLoggerConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ProgressLoggerLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetectorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetectorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_-1.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_-1Constraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_-1Layout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_FileContext.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_FileContextConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_FileContextLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_QualityRecordAggregator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_QualityRecordAggregatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_QualityRecordAggregatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_QualityScheme.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_QualitySchemeConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_QualitySchemeLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_Range.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_RangeConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityEncodingDetector_RangeLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_QualityUtilLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ReferenceSequenceMask.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ReferenceSequenceMaskConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ReferenceSequenceMaskLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ResourceLimitedMap.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ResourceLimitedMapConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ResourceLimitedMapFunctor.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ResourceLimitedMapFunctorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ResourceLimitedMapFunctorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ResourceLimitedMapLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ResourceLimitedMap_-1.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ResourceLimitedMap_-1Constraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_ResourceLimitedMap_-1Layout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_RExecutor.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_RExecutorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_RExecutorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamLocusIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamLocusIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamLocusIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamLocusIterator_LocusInfo.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamLocusIterator_LocusInfoConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamLocusIterator_LocusInfoLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamLocusIterator_RecordAndOffset.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamLocusIterator_RecordAndOffsetConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamLocusIterator_RecordAndOffsetLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIteratorFactory.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIteratorFactoryConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIteratorFactoryLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIteratorFactory_StopAfterFilteringIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIteratorFactory_StopAfterFilteringIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SamRecordIntervalIteratorFactory_StopAfterFilteringIteratorLayout.zip",
			//			"../AltogetherLayers/net_sf_picard_util_SamRecordIntervalIteratorLayout.zip",
			//			"../AltogetherLayers/net_sf_picard_util_SolexaQualityConverter.zip",
			//			"../AltogetherLayers/net_sf_picard_util_SolexaQualityConverterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_SolexaQualityConverterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_TabbedInputParser.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_TabbedInputParserConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_TabbedInputParserLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParser.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParserConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParserLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParser_Row.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParser_RowConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParser_RowLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParser_TheIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParser_TheIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_TabbedTextFileWithHeaderParser_TheIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_WholeGenomeReferenceSequenceMask.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_WholeGenomeReferenceSequenceMaskConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_picard_util_WholeGenomeReferenceSequenceMaskLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndexConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndexLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_IndexFileBuffer.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_IndexFileBufferConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_IndexFileBufferLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_IndexStreamBuffer.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_IndexStreamBufferConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_IndexStreamBufferLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_MemoryMappedFileBuffer.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_MemoryMappedFileBufferConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_MemoryMappedFileBufferLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_RandomAccessFileBuffer.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_RandomAccessFileBufferConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractBAMFileIndex_RandomAccessFileBufferLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractSAMHeaderRecord.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractSAMHeaderRecordConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AbstractSAMHeaderRecordLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AlignmentBlock.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AlignmentBlockConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AlignmentBlockLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AsyncSAMFileWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AsyncSAMFileWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_AsyncSAMFileWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMFileConstants.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMFileConstantsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMFileConstantsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMFileSpan.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMFileSpanConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMFileSpanLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMFileWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMFileWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMFileWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndex.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexContent.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexContentConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexContentLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexContent_BinList.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexContent_BinListConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexContent_BinListLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexContent_BinList_BinIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexContent_BinList_BinIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexContent_BinList_BinIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexer.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexerConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexerLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexer_BAMIndexBuilder.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexer_BAMIndexBuilderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexer_BAMIndexBuilderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexMetaData.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexMetaDataConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexMetaDataLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BamIndexValidator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BamIndexValidatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BamIndexValidatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BAMIndexWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_Bin.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinaryBAMIndexWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinaryBAMIndexWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinaryBAMIndexWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinaryCigarCodec.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinaryCigarCodecConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinaryCigarCodecLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinaryTagCodec.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinaryTagCodecConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinaryTagCodecLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinList.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinListConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinListLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinList_BinIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinList_BinIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BinList_BinIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BrowseableBAMIndex.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BrowseableBAMIndexConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_BrowseableBAMIndexLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_CachingBAMFileIndex.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_CachingBAMFileIndexConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_CachingBAMFileIndexLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_Chunk.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_ChunkConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_ChunkLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_Cigar.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_CigarConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_CigarElement.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_CigarElementConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_CigarElementLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_CigarLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_CigarOperator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_CigarOperatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_CigarOperatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_Defaults.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_DefaultSAMRecordFactory.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_DefaultSAMRecordFactoryConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_DefaultSAMRecordFactoryLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_DefaultsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_DefaultsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_DiskBasedBAMFileIndex.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_DiskBasedBAMFileIndexConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_DiskBasedBAMFileIndexLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_FileTruncatedException.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_FileTruncatedExceptionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_FileTruncatedExceptionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_FixBAMFile.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_FixBAMFileConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_FixBAMFileLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_LinearIndex.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_LinearIndexConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_LinearIndexLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_NotPrimarySkippingIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_NotPrimarySkippingIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_NotPrimarySkippingIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMBinaryTagAndUnsignedArrayValue.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMBinaryTagAndUnsignedArrayValueConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMBinaryTagAndUnsignedArrayValueLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMBinaryTagAndValue.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMBinaryTagAndValueConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMBinaryTagAndValueLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMException.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMExceptionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMExceptionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileHeader.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileHeaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileHeaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileHeader_GroupOrder.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileHeader_GroupOrderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileHeader_GroupOrderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileHeader_SortOrder.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileHeader_SortOrderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileHeader_SortOrderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileSource.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileSourceConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileSourceLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileSpan.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileSpanConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileSpanLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileTruncatedReader.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileTruncatedReaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileTruncatedReaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileTruncatedReader_TruncatedIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileTruncatedReader_TruncatedIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileTruncatedReader_TruncatedIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileWriterFactory.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileWriterFactoryConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileWriterFactoryLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileWriterImpl.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileWriterImplConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileWriterImplLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFileWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFormatException.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFormatExceptionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMFormatExceptionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMProgramRecord.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMProgramRecordConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMProgramRecordLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMReadGroupRecord.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMReadGroupRecordConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMReadGroupRecordLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecord.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordComparator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordComparatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordComparatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordCoordinateComparator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordCoordinateComparatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordCoordinateComparatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordFactory.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordFactoryConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordFactoryLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordQueryNameComparator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordQueryNameComparatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordQueryNameComparatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordSetBuilder.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordSetBuilderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordSetBuilderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordSetBuilder_-1.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordSetBuilder_-1Constraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordSetBuilder_-1Layout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecordUtilLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecord_SAMTagAndValue.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecord_SAMTagAndValueConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMRecord_SAMTagAndValueLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMSequenceRecord.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMSequenceRecordConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMSequenceRecordLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMSortOrderChecker.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMSortOrderCheckerConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMSortOrderCheckerLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTag.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTagConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTagLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTagUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTagUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTagUtilLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTestUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTestUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTestUtilLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTextWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTextWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTextWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMTools.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMToolsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMToolsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMValidationError.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMValidationErrorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMValidationErrorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMValidationError_Severity.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMValidationError_SeverityConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMValidationError_SeverityLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMValidationError_Type.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMValidationError_TypeConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SAMValidationError_TypeLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SQTagUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SQTagUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SQTagUtilLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SQTagUtil_SQBase.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SQTagUtil_SQBaseConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_SQTagUtil_SQBaseLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TagValueAndUnsignedArrayFlag.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TagValueAndUnsignedArrayFlagConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TagValueAndUnsignedArrayFlagLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TextCigarCodec.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TextCigarCodecConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TextCigarCodecLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TextTagCodec.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TextTagCodecConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TextTagCodecLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TextTagCodec_-1.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TextTagCodec_-1Constraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TextTagCodec_-1Layout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TextualBAMIndexWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TextualBAMIndexWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_TextualBAMIndexWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_AbstractAsyncWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_AbstractAsyncWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_AbstractAsyncWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_AbstractAsyncWriter_WriterRunnable.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_AbstractAsyncWriter_WriterRunnableConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_AbstractAsyncWriter_WriterRunnableLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_AsciiWriter.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_AsciiWriterConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_AsciiWriterLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BinaryCodec.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BinaryCodecConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BinaryCodecLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedFilePointerUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedFilePointerUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedFilePointerUtilLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedInputStream.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedInputStreamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedInputStreamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedInputStream_FileTermination.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedInputStream_FileTerminationConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedInputStream_FileTerminationLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedOutputStream.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedOutputStreamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedOutputStreamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedStreamConstants.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedStreamConstantsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockCompressedStreamConstantsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockGunzipper.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockGunzipperConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BlockGunzipperLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BufferedLineReader.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BufferedLineReaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_BufferedLineReaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_CloseableIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_CloseableIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_CloseableIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_CloserUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_CloserUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_CloserUtilLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_CoordMath.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_CoordMathConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_CoordMathLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_DateParser.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_DateParserConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_DateParserLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_DateParser_InvalidDateException.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_DateParser_InvalidDateExceptionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_DateParser_InvalidDateExceptionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_DelegatingIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_DelegatingIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_DelegatingIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_HttpUtils.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_HttpUtilsConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_HttpUtilsLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_IOUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_IOUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_IOUtilLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_Iso8601Date.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_Iso8601DateConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_Iso8601DateLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_Iso8601Date_-1.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_Iso8601Date_-1Constraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_Iso8601Date_-1Layout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_LineReader.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_LineReaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_LineReaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_Md5CalculatingInputStream.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_Md5CalculatingInputStreamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_Md5CalculatingInputStreamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_Md5CalculatingOutputStream.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_Md5CalculatingOutputStreamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_Md5CalculatingOutputStreamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_PeekIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_PeekIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_PeekIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_RuntimeEOFException.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_RuntimeEOFExceptionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_RuntimeEOFExceptionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_RuntimeIOException.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_RuntimeIOExceptionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_RuntimeIOExceptionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SeekableBufferedStream.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SeekableBufferedStreamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SeekableBufferedStreamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SeekableFileStream.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SeekableFileStreamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SeekableFileStreamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SeekableHTTPStream.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SeekableHTTPStreamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SeekableHTTPStreamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SeekableStream.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SeekableStreamConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SeekableStreamLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SequenceUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SequenceUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SequenceUtilLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SequenceUtil_SequenceListsDifferException.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SequenceUtil_SequenceListsDifferExceptionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SequenceUtil_SequenceListsDifferExceptionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SnappyLoader.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SnappyLoaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SnappyLoaderLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollectionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollectionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_Codec.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_CodecConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_CodecLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_FileRecordIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_FileRecordIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_FileRecordIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_InMemoryIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_InMemoryIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_InMemoryIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_MergingIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_MergingIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_MergingIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_PeekFileRecordIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_PeekFileRecordIteratorComparator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_PeekFileRecordIteratorComparatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_PeekFileRecordIteratorComparatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_PeekFileRecordIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_PeekFileRecordIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_PollableTreeSet.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_PollableTreeSetConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingCollection_PollableTreeSetLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollectionConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollectionLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection_FileValueIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection_FileValueIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection_FileValueIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection_PeekFileValueIterator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection_PeekFileValueIteratorComparator.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection_PeekFileValueIteratorComparatorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection_PeekFileValueIteratorComparatorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection_PeekFileValueIteratorConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_SortingLongCollection_PeekFileValueIteratorLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_StopWatch.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_StopWatchConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_StopWatchLayout.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_StringLineReader.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_StringLineReaderConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_StringLineReaderLayout.zip",
			"../AltogetherLayers/net_sf_samtools_util_StringUtil.zip",
			"../AltogetherLayers/net_sf_samtools_util_StringUtilConstraints.zip",
			"../AltogetherLayers/net_sf_samtools_util_StringUtilLayout.zip",
			"../AltogetherLayers/net_sf_samtools_util_TempStreamFactory.zip",
			"../AltogetherLayers/net_sf_samtools_util_TempStreamFactoryConstraints.zip",
			"../AltogetherLayers/net_sf_samtools_util_TempStreamFactoryLayout.zip"
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_TestUtil.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_TestUtilConstraints.zip",
			//			"c:\\AltogetherLayers\\net_sf_samtools_util_TestUtilLayout.zip"
		);
		
		static public var tutorialButtonWorldFile:String = "../SampleWorlds/DemoWorld/tutorial.zip";
		static public var tutorialButtonLayoutFile:String = "../SampleWorlds/DemoWorld/tutorialLayout.zip";
		static public var tutorialButtonConstraintsFile:String = "../SampleWorlds/DemoWorld/tutorialConstraints.zip";
		static public var numTutorialLevels:int = 0;
		static public var numTutorialLevelsCompleted:int = 0;
		static public var inTutorial:Boolean = false;
		
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